import SwiftUI

struct OrderRowView: View {
    let order: Order
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                selectionIndicator
                itemImage
                orderInfo
                Spacer()
                trailingInfo
            }
            .padding(14)
            .background(isSelected ? Color.ebayBlue.opacity(0.08) : Color(UIColor.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.ebayBlue : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isMultiSelectMode {
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.ebayBlue : Color.gray.opacity(0.4), lineWidth: 2)
                    .frame(width: 24, height: 24)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.ebayBlue)
                        .font(.system(size: 24))
                }
            }
        }
    }

    private var itemImage: some View {
        Group {
            if let imageUrl = order.firstItemImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.ebayBlue.opacity(0.1))
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(.ebayBlue.opacity(0.5))
        }
    }

    private var orderInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(order.buyer.username)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text(order.firstItemTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 6) {
                statusBadge
                Text(order.id.prefix(12) + "...")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var statusBadge: some View {
        Text(order.displayStatus)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch order.orderFulfillmentStatus {
        case .fulfilled: return .ebayGreen
        case .inProgress: return .orange
        case .notStarted: return .ebayRed
        }
    }

    private var trailingInfo: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(order.totalAmount)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(order.lastModifiedDate.conversationTimestamp)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if order.unreadMessageCount > 0 {
                Text("\(order.unreadMessageCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Color.ebayBlue)
                    .clipShape(Circle())
            }
        }
    }
}
