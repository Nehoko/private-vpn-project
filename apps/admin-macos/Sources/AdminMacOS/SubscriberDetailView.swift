import SwiftUI

struct SubscriberDetailContainer: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        Group {
            if let subscriber = state.selectedSubscriber {
                SubscriberDetailView(
                    subscriber: subscriber,
                    isExpiringSoon: state.expiringSoonIDs.contains(subscriber.id),
                    lastUpdate: state.lastUpdate
                )
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "sidebar.right",
                    description: Text("Pick subscriber from sidebar or create new one.")
                )
            }
        }
    }
}

private struct SubscriberDetailView: View {
    let subscriber: Subscriber
    let isExpiringSoon: Bool
    let lastUpdate: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 180), alignment: .leading)
                ], alignment: .leading, spacing: 12) {
                    MetricCard(title: "Next Payup", value: subscriber.dueDateLabel, accent: isExpiringSoon ? .orange : .blue)
                    MetricCard(title: "Started", value: subscriber.startDateLabel, accent: .secondary)
                    MetricCard(title: "Telegram", value: "#\(subscriber.telegramId)", accent: .mint)
                    MetricCard(title: "Last update", value: lastUpdate, accent: .secondary)
                }

                detailCard
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriber.displayName)
                        .font(.largeTitle.weight(.semibold))
                    Text(subscriber.shortLabel)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusBadge(active: subscriber.active, isExpiringSoon: isExpiringSoon)
            }

            Text(summaryText)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Subscriber Details")
                .font(.headline)

            DetailRow(label: "First name", value: subscriber.firstName)
            DetailRow(label: "Last name", value: subscriber.lastName ?? "—")
            DetailRow(label: "Telegram username", value: subscriber.shortLabel)
            DetailRow(label: "Telegram ID", value: String(subscriber.telegramId))
            DetailRow(label: "Start date", value: subscriber.startDateLabel)
            DetailRow(label: "Next payup", value: subscriber.dueDateLabel)
            DetailRow(label: "Activity", value: subscriber.active ? "Active" : "Inactive")
            DetailRow(label: "Calendar", value: subscriber.calendarStatusLabel)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var summaryText: String {
        if !subscriber.active {
            return "Subscriber inactive. Calendar reminder removed until reactivated."
        }

        if isExpiringSoon {
            return "Subscription needs attention soon. Calendar event carries D-3 alert."
        }

        return "Manual local flow. Edit subscriber anytime. Calendar event stays synced on save."
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(accent.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct StatusBadge: View {
    let active: Bool
    let isExpiringSoon: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbolName)
            Text(label)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColor.opacity(0.14), in: Capsule())
        .foregroundStyle(backgroundColor)
    }

    private var symbolName: String {
        if !active {
            return "pause.circle.fill"
        }
        return isExpiringSoon ? "bell.badge.fill" : "checkmark.circle.fill"
    }

    private var label: String {
        if !active {
            return "Inactive"
        }
        return isExpiringSoon ? "Expiring Soon" : "Active"
    }

    private var backgroundColor: Color {
        if !active {
            return .secondary
        }
        return isExpiringSoon ? .orange : .green
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
    }
}
