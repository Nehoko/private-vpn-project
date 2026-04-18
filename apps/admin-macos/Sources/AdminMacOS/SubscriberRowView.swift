import SwiftUI

struct SubscriberRowView: View {
    let subscriber: Subscriber
    let isExpiringSoon: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: subscriber.active ? "lock.shield" : "pause.circle")
                .foregroundStyle(isExpiringSoon ? .orange : .secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(subscriber.displayName)
                        .lineLimit(1)

                    if isExpiringSoon {
                        Text("Due")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                }

                Text("\(subscriber.shortLabel) • \(subscriber.dueDateLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
