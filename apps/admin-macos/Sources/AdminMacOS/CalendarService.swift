import EventKit
import Foundation

enum CalendarServiceError: LocalizedError {
    case accessDenied
    case defaultCalendarMissing

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied. Grant Calendar permission in System Settings."
        case .defaultCalendarMissing:
            return "No writable default calendar available."
        }
    }
}

@MainActor
final class CalendarService {
    private let eventStore = EKEventStore()

    func syncEvent(for subscriber: Subscriber) async throws -> String? {
        guard subscriber.active else {
            try await removeEvent(identifier: subscriber.calendarEventIdentifier)
            return nil
        }

        try await ensureAccess()

        let event = subscriber.calendarEventIdentifier.flatMap(eventStore.event(withIdentifier:)) ?? EKEvent(eventStore: eventStore)
        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw CalendarServiceError.defaultCalendarMissing
        }

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
        try await withCheckedThrowingContinuation { continuation in
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToEvents { accessGranted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: accessGranted)
                    }
                }
            } else {
                eventStore.requestAccess(to: .event) { accessGranted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: accessGranted)
                    }
                }
            }
        }
    }
}
