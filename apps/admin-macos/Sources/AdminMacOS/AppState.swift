import AppKit
import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class AppState: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    private enum Keys {
        static let apiBaseURL = "apiBaseURL"
        static let apiToken = "apiToken"
        static let hasSeenWelcome = "hasSeenWelcome"
        static let deliveredNotifications = "deliveredNotifications"
    }
    
    private static let pollingIntervalNanoseconds: UInt64 = 21_600_000_000_000

    @Published var subscribers: [Subscriber] = []
    @Published var expiringSoon: [Subscriber] = []
    @Published var searchText = ""
    @Published var lastRefresh: String = "Never"
    @Published var selectedSubscriberID: String?
    @Published var selectedFilter: SubscriberFilter = .all
    @Published var isRefreshing = false
    @Published var lastError: String?
    @Published var isShowingConnectionSheet = false
    @Published var connectionSettings: ConnectionSettings

    private let apiClient = APIClient()
    private let notificationsAvailable = Bundle.main.bundleURL.pathExtension == "app"
    private var pollingTask: Task<Void, Never>?

    override init() {
        let defaults = UserDefaults.standard
        let defaultBaseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://127.0.0.1:8080"
        let defaultToken = ProcessInfo.processInfo.environment["API_TOKEN"] ?? "change-me"

        self.connectionSettings = ConnectionSettings(
            baseURL: defaults.string(forKey: Keys.apiBaseURL) ?? defaultBaseURL,
            token: defaults.string(forKey: Keys.apiToken) ?? defaultToken
        )
        super.init()
    }

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

    var expiringSoonIDs: Set<String> {
        Set(expiringSoon.map(\.id))
    }

    var activeCount: Int {
        subscribers.filter(\.active).count
    }

    var inactiveCount: Int {
        subscribers.count - activeCount
    }

    func start() async {
        if shouldShowWelcome {
            isShowingConnectionSheet = true
        }

        startPollingLoop()

        if notificationsAvailable {
            UNUserNotificationCenter.current().delegate = self
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        }
        await refresh()
    }

    func refresh() async {
        guard connectionSettings.canSave else {
            lastError = "Set API URL and token before refresh."
            isShowingConnectionSheet = true
            return
        }

        isRefreshing = true
        lastError = nil
        defer { isRefreshing = false }

        do {
            let bootstrap = try await apiClient.bootstrap(settings: connectionSettings)
            subscribers = bootstrap.subscribers
            expiringSoon = bootstrap.expiringSoon
            lastRefresh = Self.formatTimestamp(bootstrap.generatedAt)
            syncSelection()
            trimDeliveredNotifications()
            await notifyDueSubscribers()
        } catch {
            lastError = error.localizedDescription
            print("Bootstrap failed:", error)
        }
    }

    func saveConnectionSettings() {
        guard connectionSettings.canSave else {
            lastError = "Enter valid API URL and token."
            return
        }

        let defaults = UserDefaults.standard
        defaults.set(connectionSettings.sanitizedBaseURL, forKey: Keys.apiBaseURL)
        defaults.set(connectionSettings.sanitizedToken, forKey: Keys.apiToken)
        defaults.set(true, forKey: Keys.hasSeenWelcome)
        connectionSettings = ConnectionSettings(
            baseURL: connectionSettings.sanitizedBaseURL,
            token: connectionSettings.sanitizedToken
        )
        isShowingConnectionSheet = false

        Task {
            await refresh()
        }
    }

    func openConnectionSettings() {
        isShowingConnectionSheet = true
    }

    private func notifyDueSubscribers() async {
        guard notificationsAvailable else {
            return
        }

        for subscriber in expiringSoon {
            let notificationKey = notificationKey(for: subscriber)
            if deliveredNotificationKeys.contains(notificationKey) {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "VPN subscription needs attention"
            content.body = "@\(subscriber.telegramUsername) due \(subscriber.nextPayupDate)"
            let request = UNNotificationRequest(
                identifier: "subscriber-\(subscriber.id)",
                content: content,
                trigger: nil
            )
            try? await UNUserNotificationCenter.current().add(request)
            deliveredNotificationKeys.insert(notificationKey)
        }
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

    private static func formatTimestamp(_ input: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: input) {
            return date.relativeRefreshLabel()
        }
        return input
    }

    private func startPollingLoop() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: Self.pollingIntervalNanoseconds)
                } catch {
                    break
                }

                guard !Task.isCancelled, let self else {
                    break
                }

                await self.refresh()
            }
        }
    }

    private func notificationKey(for subscriber: Subscriber) -> String {
        [subscriber.id, subscriber.nextPayupDate].joined(separator: ":")
    }

    private var deliveredNotificationKeys: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: Keys.deliveredNotifications) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue).sorted(), forKey: Keys.deliveredNotifications)
        }
    }

    private func trimDeliveredNotifications() {
        let activeKeys = Set(expiringSoon.map(notificationKey(for:)))
        deliveredNotificationKeys = deliveredNotificationKeys.intersection(activeKeys)
    }

    private var shouldShowWelcome: Bool {
        let defaults = UserDefaults.standard
        let hasSeenWelcome = defaults.bool(forKey: Keys.hasSeenWelcome)
        return !hasSeenWelcome || !connectionSettings.canSave
    }

    deinit {
        pollingTask?.cancel()
    }
}
