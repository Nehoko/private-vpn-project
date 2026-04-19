import Foundation

@MainActor
final class AppState: ObservableObject {
    private let store = SubscriberStore()
    private let calendarService = CalendarService()

    @Published var subscribers: [Subscriber] = []
    @Published var searchText = ""
    @Published var lastError: String?
    @Published var bannerMessage: BannerMessage?
    @Published var lastUpdate = "Never"
    @Published var selectedSubscriberID: UUID?
    @Published var selectedFilter: SubscriberFilter = .all
    @Published var isShowingEditor = false
    @Published var editorMode: EditorMode = .create
    @Published var editorDraft = SubscriberDraft()
    @Published var isDeleteConfirmationPresented = false
    @Published var isCalendarSyncing = false

    var filteredSubscribers: [Subscriber] {
        subscribers.filter { subscriber in
            guard subscriber.matches(searchText: searchText) else {
                return false
            }

            switch selectedFilter {
            case .all:
                return true
            case .expiringSoon:
                return expiringSoonIDs.contains(subscriber.id)
            case .active:
                return subscriber.active
            case .inactive:
                return !subscriber.active
            }
        }
    }

    var selectedSubscriber: Subscriber? {
        guard let selectedSubscriberID else {
            return filteredSubscribers.first ?? subscribers.first
        }
        return subscribers.first { $0.id == selectedSubscriberID }
    }

    var expiringSoon: [Subscriber] {
        subscribers.filter { subscriber in
            guard subscriber.active else {
                return false
            }
            let days = subscriber.nextPayupDate.daysUntil()
            return days >= 0 && days <= 3
        }
    }

    var expiringSoonIDs: Set<UUID> {
        Set(expiringSoon.map(\.id))
    }

    var activeCount: Int {
        subscribers.filter(\.active).count
    }

    var inactiveCount: Int {
        subscribers.count - activeCount
    }

    var lastUpdateLabel: String {
        "Last update: \(lastUpdate)"
    }

    var deleteConfirmationTitle: String {
        guard let selectedSubscriber else {
            return "Delete subscriber"
        }
        return "Delete \(selectedSubscriber.displayName)?"
    }

    var deleteConfirmationMessage: String {
        "Subscriber record deleted. Calendar reminder removed too."
    }

    var toolbarCanEdit: Bool {
        selectedSubscriber != nil
    }

    func start() async {
        load()
    }

    func load() {
        lastError = nil

        do {
            let snapshot = try store.load()
            subscribers = snapshot.subscribers.sorted(by: Self.sortSubscribers)
            lastUpdate = snapshot.updatedAt.relativeRefreshLabel()
            syncSelection()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func openCreateSubscriber() {
        editorMode = .create
        editorDraft = SubscriberDraft()
        isShowingEditor = true
    }

    func openEditSubscriber() {
        guard let subscriber = selectedSubscriber else {
            lastError = "Select subscriber first."
            return
        }

        editorMode = .edit
        editorDraft = SubscriberDraft(subscriber: subscriber)
        isShowingEditor = true
    }

    func closeEditor() {
        isShowingEditor = false
    }

    func saveEditor() async {
        do {
            let isCreating = editorMode == .create
            var subscriber = try editorDraft.buildSubscriber()
            let existingEventID = subscribers.first(where: { $0.id == subscriber.id })?.calendarEventIdentifier
            subscriber.calendarEventIdentifier = existingEventID ?? subscriber.calendarEventIdentifier

            do {
                if subscriber.active {
                    subscriber.calendarEventIdentifier = try await calendarService.syncEvent(for: subscriber)
                } else {
                    try await calendarService.removeEvent(identifier: subscriber.calendarEventIdentifier)
                    subscriber.calendarEventIdentifier = nil
                }
            } catch {
                subscriber.calendarEventIdentifier = nil
                lastError = "Subscriber saved, but Calendar sync failed: \(error.localizedDescription)"
            }

            upsert(subscriber)
            try persist()
            isShowingEditor = false
            showBanner(
                subscriber.active
                    ? "\(isCreating ? "Subscriber added" : "Subscriber updated"). Calendar event synced to \(CalendarService.managedCalendarTitle)."
                    : "\(isCreating ? "Subscriber added" : "Subscriber updated"). Reminder removed because subscriber inactive.",
                tone: .success
            )
        } catch {
            lastError = error.localizedDescription
        }
    }

    func promptDeleteSelected() {
        guard selectedSubscriber != nil else {
            lastError = "Select subscriber first."
            return
        }
        isDeleteConfirmationPresented = true
    }

    func deleteSelectedSubscriber() async {
        guard let subscriber = selectedSubscriber else {
            return
        }

        do {
            do {
                try await calendarService.removeEvent(identifier: subscriber.calendarEventIdentifier)
            } catch {
                lastError = "Subscriber deleted, but Calendar cleanup failed: \(error.localizedDescription)"
            }
            subscribers.removeAll { $0.id == subscriber.id }
            try persist()
            syncSelection()
            isDeleteConfirmationPresented = false
            showBanner("Subscriber deleted. Calendar reminder removed.", tone: .info)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func syncCalendarEvents() async {
        isCalendarSyncing = true
        defer { isCalendarSyncing = false }

        do {
            var synced: [Subscriber] = []

            for var subscriber in subscribers {
                if subscriber.active {
                    subscriber.calendarEventIdentifier = try await calendarService.syncEvent(for: subscriber)
                } else {
                    try await calendarService.removeEvent(identifier: subscriber.calendarEventIdentifier)
                    subscriber.calendarEventIdentifier = nil
                }
                synced.append(subscriber)
            }

            subscribers = synced.sorted(by: Self.sortSubscribers)
            try persist()
            let activeSubscribers = synced.filter(\.active).count
            showBanner(
                activeSubscribers == 0
                    ? "No active subscribers. \(CalendarService.managedCalendarTitle) calendar clean."
                    : "Calendar synced for \(activeSubscribers) active subscriber\(activeSubscribers == 1 ? "" : "s") in \(CalendarService.managedCalendarTitle).",
                tone: .success
            )
        } catch {
            lastError = error.localizedDescription
        }
    }

    func dismissBanner() {
        bannerMessage = nil
    }

    func selectFirstVisibleSubscriber() {
        if selectedSubscriberID == nil {
            selectedSubscriberID = filteredSubscribers.first?.id ?? subscribers.first?.id
        }
    }

    private func syncSelection() {
        if let selectedSubscriberID, subscribers.contains(where: { $0.id == selectedSubscriberID }) {
            return
        }

        selectedSubscriberID = filteredSubscribers.first?.id ?? subscribers.first?.id
    }

    private func upsert(_ subscriber: Subscriber) {
        if let index = subscribers.firstIndex(where: { $0.id == subscriber.id }) {
            subscribers[index] = subscriber
        } else {
            subscribers.append(subscriber)
        }

        subscribers.sort(by: Self.sortSubscribers)
        selectedSubscriberID = subscriber.id
    }

    private func persist() throws {
        let snapshot = try store.save(subscribers: subscribers.sorted(by: Self.sortSubscribers))
        subscribers = snapshot.subscribers.sorted(by: Self.sortSubscribers)
        lastUpdate = snapshot.updatedAt.relativeRefreshLabel()
    }

    private func showBanner(_ text: String, tone: BannerTone) {
        bannerMessage = BannerMessage(text: text, tone: tone)
    }

    private static func sortSubscribers(lhs: Subscriber, rhs: Subscriber) -> Bool {
        if lhs.active != rhs.active {
            return lhs.active && !rhs.active
        }

        if lhs.nextPayupDate != rhs.nextPayupDate {
            return lhs.nextPayupDate < rhs.nextPayupDate
        }

        return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
    }
}
