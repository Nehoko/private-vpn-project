import Foundation

struct Subscriber: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String?
    let telegramUsername: String
    let telegramId: Int
    let startDate: String
    let nextPayupDate: String
    let active: Bool
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

extension Subscriber {
    var displayName: String {
        let name = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
        return name.isEmpty ? "@\(telegramUsername)" : name
    }

    var shortLabel: String {
        "@\(telegramUsername)"
    }

    var dueDate: Date? {
        DateFormatter.isoDate.date(from: nextPayupDate)
    }

    var startDateValue: Date? {
        DateFormatter.isoDate.date(from: startDate)
    }

    var dueDateLabel: String {
        DateFormatter.uiDate.string(from: dueDate ?? .now)
    }

    var startDateLabel: String {
        DateFormatter.uiDate.string(from: startDateValue ?? .now)
    }

    func matches(searchText: String) -> Bool {
        if searchText.isEmpty {
            return true
        }

        let normalized = searchText.localizedLowercase
        return displayName.localizedLowercase.contains(normalized) ||
            telegramUsername.localizedLowercase.contains(normalized) ||
            String(telegramId).contains(normalized)
    }
}

struct BootstrapResponse: Codable {
    let generatedAt: String
    let subscribers: [Subscriber]
    let expiringSoon: [Subscriber]
    let cursor: String
}

struct ConnectionSettings {
    var baseURL: String
    var token: String

    var sanitizedBaseURL: String {
        baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var sanitizedToken: String {
        token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        URL(string: sanitizedBaseURL) != nil && !sanitizedToken.isEmpty
    }
}

extension DateFormatter {
    static let isoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

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
}
