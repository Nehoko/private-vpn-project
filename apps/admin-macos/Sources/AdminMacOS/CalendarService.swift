import EventKit
import Foundation

enum CalendarServiceError: LocalizedError {
    case accessDenied
    case defaultCalendarMissing
    case calendarSourceMissing

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied. Grant Calendar permission in System Settings."
        case .defaultCalendarMissing:
            return "No writable default calendar available."
        case .calendarSourceMissing:
            return "No writable calendar source available."
        }
    }
}

@MainActor
final class CalendarService {
    nonisolated static let managedCalendarTitle = "Private VPN Admin"

    private let eventStore = EKEventStore()
    private let defaults = UserDefaults.standard
    private let managedCalendarIdentifierKey = "managedCalendarIdentifier"

    func syncEvent(for subscriber: Subscriber) async throws -> String? {
        guard subscriber.active else {
            try await removeEvent(identifier: subscriber.calendarEventIdentifier)
            return nil
        }

        try await ensureAccess()

        let event = subscriber.calendarEventIdentifier.flatMap(eventStore.event(withIdentifier:)) ?? EKEvent(eventStore: eventStore)
        let calendar = try preferredCalendar()

        let startDate = Calendar.current.startOfDay(for: subscriber.nextPayupDate)
        event.calendar = calendar
        event.title = subscriber.expirationEventTitle
        event.isAllDay = true
        event.startDate = startDate
        event.endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)
        event.notes = """
        VPN subscriber: \(subscriber.displayName)
        Telegram: \(subscriber.shortLabel)
        Telegram ID: \(subscriber.telegramId)
        """
        event.alarms = [EKAlarm(relativeOffset: -259_200)]

        try eventStore.save(event, span: .thisEvent, commit: true)
        return event.eventIdentifier
    }

    func removeEvent(identifier: String?) async throws {
        guard let identifier else {
            return
        }

        try await ensureAccess()
        guard let event = eventStore.event(withIdentifier: identifier) else {
            return
        }
        try eventStore.remove(event, span: .thisEvent, commit: true)
    }

    private func ensureAccess() async throws {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .fullAccess, .writeOnly:
            return
        case .notDetermined:
            let granted = try await requestAccess()

            if !granted {
                throw CalendarServiceError.accessDenied
            }
        case .denied, .restricted:
            throw CalendarServiceError.accessDenied
        @unknown default:
            throw CalendarServiceError.accessDenied
        }
    }

    private func requestAccess() async throws -> Bool {
        let eventStore = self.eventStore
        let handler = makeCalendarAccessHandler

        return try await withCheckedThrowingContinuation { continuation in
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToEvents(completion: handler(continuation))
            } else {
                eventStore.requestAccess(to: .event, completion: handler(continuation))
            }
        }
    }

    private func preferredCalendar() throws -> EKCalendar {
        if let identifier = defaults.string(forKey: managedCalendarIdentifierKey),
           let calendar = eventStore.calendar(withIdentifier: identifier),
           calendar.allowsContentModifications {
            return calendar
        }

        if let existingCalendar = eventStore.calendars(for: .event).first(where: {
            $0.title == Self.managedCalendarTitle && $0.allowsContentModifications
        }) {
            defaults.set(existingCalendar.calendarIdentifier, forKey: managedCalendarIdentifierKey)
            return existingCalendar
        }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        guard let source = writableSource() else {
            throw CalendarServiceError.calendarSourceMissing
        }

        calendar.title = Self.managedCalendarTitle
        calendar.source = source
        try eventStore.saveCalendar(calendar, commit: true)
        defaults.set(calendar.calendarIdentifier, forKey: managedCalendarIdentifierKey)
        return calendar
    }

    private func writableSource() -> EKSource? {
        if let source = eventStore.defaultCalendarForNewEvents?.source {
            return source
        }

        let preferredTypes: [EKSourceType] = [.local, .calDAV, .exchange, .mobileMe]
        for sourceType in preferredTypes {
            if let source = eventStore.sources.first(where: { $0.sourceType == sourceType }) {
                return source
            }
        }

        return eventStore.sources.first
    }
}

private func makeCalendarAccessHandler(
    _ continuation: CheckedContinuation<Bool, Error>
) -> @Sendable (Bool, Error?) -> Void {
    { accessGranted, error in
        if let error {
            continuation.resume(throwing: error)
        } else {
            continuation.resume(returning: accessGranted)
        }
    }
}
