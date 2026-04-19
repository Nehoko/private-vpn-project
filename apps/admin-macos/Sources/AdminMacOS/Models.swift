import Foundation

struct Subscriber: Codable, Identifiable, Equatable {
    let id: UUID
    var firstName: String
    var lastName: String?
    var telegramUsername: String
    var telegramId: Int
    var startDate: Date
    var nextPayupDate: Date
    var active: Bool
    var calendarEventIdentifier: String?
}

struct PersistenceSnapshot: Codable {
    var updatedAt: Date
    var subscribers: [Subscriber]
}

enum SubscriberFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case expiringSoon = "Expiring Soon"
    case active = "Active"
    case inactive = "Inactive"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .all:
            return "person.3.sequence"
        case .expiringSoon:
            return "bell.badge"
        case .active:
            return "checkmark.circle"
        case .inactive:
            return "pause.circle"
        }
    }
}

enum EditorMode: String {
    case create = "New Subscriber"
    case edit = "Edit Subscriber"
}

struct SubscriberDraft {
    var id: UUID?
    var firstName = ""
    var lastName = ""
    var telegramUsername = ""
    var telegramId = ""
    var startDate = Date()
    var nextPayupDate = Date()
    var active = true
    var calendarEventIdentifier: String?

    init() {}

    init(subscriber: Subscriber) {
        id = subscriber.id
        firstName = subscriber.firstName
        lastName = subscriber.lastName ?? ""
        telegramUsername = subscriber.normalizedTelegramUsername
        telegramId = String(subscriber.telegramId)
        startDate = subscriber.startDate
        nextPayupDate = subscriber.nextPayupDate
        active = subscriber.active
        calendarEventIdentifier = subscriber.calendarEventIdentifier
    }

    func buildSubscriber() throws -> Subscriber {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirstName.isEmpty else {
            throw SubscriberDraftError.firstNameMissing
        }

        let normalizedUsername = telegramUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        guard !normalizedUsername.isEmpty else {
            throw SubscriberDraftError.usernameMissing
        }

        let trimmedTelegramID = telegramId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsedTelegramID = Int(trimmedTelegramID) else {
            throw SubscriberDraftError.telegramIDInvalid
        }

        return Subscriber(
            id: id ?? UUID(),
            firstName: trimmedFirstName,
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            telegramUsername: normalizedUsername,
            telegramId: parsedTelegramID,
            startDate: startDate,
            nextPayupDate: nextPayupDate,
            active: active,
            calendarEventIdentifier: calendarEventIdentifier
        )
    }
}

enum SubscriberDraftError: LocalizedError {
    case firstNameMissing
    case usernameMissing
    case telegramIDInvalid

    var errorDescription: String? {
        switch self {
        case .firstNameMissing:
            return "First name required."
        case .usernameMissing:
            return "Telegram username required."
        case .telegramIDInvalid:
            return "Telegram ID must be integer."
        }
    }
}

extension Subscriber {
    var normalizedTelegramUsername: String {
        telegramUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }

    var displayName: String {
        let name = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
        return name.isEmpty ? shortLabel : name
    }

    var shortLabel: String {
        "@\(normalizedTelegramUsername)"
    }

    var dueDateLabel: String {
        DateFormatter.uiDate.string(from: nextPayupDate)
    }

    var startDateLabel: String {
        DateFormatter.uiDate.string(from: startDate)
    }

    var expirationEventTitle: String {
        "\(shortLabel) subscription expiration"
    }

    var calendarStatusLabel: String {
        calendarEventIdentifier == nil ? "Not synced" : "Synced"
    }

    func matches(searchText: String) -> Bool {
        if searchText.isEmpty {
            return true
        }

        let normalized = searchText.localizedLowercase
        return displayName.localizedLowercase.contains(normalized) ||
            normalizedTelegramUsername.localizedLowercase.contains(normalized) ||
            String(telegramId).contains(normalized)
    }
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

extension DateFormatter {
    static let uiDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let uiTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
}

extension Date {
    func relativeRefreshLabel(now: Date = .now, calendar: Calendar = .current) -> String {
        let timeLabel = DateFormatter.uiTimestamp.string(from: self)

        if calendar.isDateInToday(self) {
            return "today at \(timeLabel)"
        }

        if calendar.isDateInYesterday(self) {
            return "yesterday at \(timeLabel)"
        }

        let startOfSelf = calendar.startOfDay(for: self)
        let startOfNow = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: startOfSelf, to: startOfNow).day ?? 0

        if days > 1 {
            return "\(days) days ago at \(timeLabel)"
        }

        return DateFormatter.uiDate.string(from: self) + " at " + timeLabel
    }

    func daysUntil(now: Date = .now, calendar: Calendar = .current) -> Int {
        let startOfSelf = calendar.startOfDay(for: self)
        let startOfNow = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: startOfNow, to: startOfSelf).day ?? 0
    }
}
