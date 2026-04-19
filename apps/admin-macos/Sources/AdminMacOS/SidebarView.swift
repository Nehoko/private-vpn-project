import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            SidebarSummaryView()
                .environmentObject(state)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            if let lastError = state.lastError {
                ContentUnavailableView {
                    Label("Action failed", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(lastError)
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            List(selection: $state.selectedSubscriberID) {
                ForEach(state.filteredSubscribers) { subscriber in
                    SubscriberRowView(
                        subscriber: subscriber,
                        isExpiringSoon: state.expiringSoonIDs.contains(subscriber.id)
                    )
                    .tag(subscriber.id)
                }
            }
            .listStyle(.sidebar)
            .overlay {
                if state.filteredSubscribers.isEmpty {
                    ContentUnavailableView(
                        "No Subscribers",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text("Create subscriber or adjust search/filter.")
                    )
                }
            }
        }
        .searchable(text: $state.searchText, placement: .sidebar)
    }
}

private struct SidebarSummaryView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Private VPN")
                .font(.title2.weight(.semibold))

            HStack(spacing: 12) {
                SummaryPill(title: "All", value: "\(state.subscribers.count)", tint: .primary)
                SummaryPill(title: "Due", value: "\(state.expiringSoon.count)", tint: .orange)
                SummaryPill(title: "Inactive", value: "\(state.inactiveCount)", tint: .secondary)
            }

            Text(state.lastUpdateLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SummaryPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(tint.opacity(0.22))
        }
    }
}
