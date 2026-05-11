import SwiftUI

struct ConversationsListView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @ObservedObject var ordersVM: OrdersViewModel
    @State private var searchText = ""

    var filteredConversations: [Conversation] {
        guard !searchText.isEmpty else { return conversationVM.conversations }
        return conversationVM.conversations.filter {
            $0.buyer.username.localizedCaseInsensitiveContains(searchText) ||
            $0.itemTitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if conversationVM.isLoading && conversationVM.conversations.isEmpty {
                    LoadingView(message: "Loading conversations...")
                } else if conversationVM.conversations.isEmpty && !conversationVM.isLoading {
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "No Conversations",
                        subtitle: "Conversations with buyers will appear here once you have active orders.",
                        actionTitle: "Refresh",
                        action: { Task { await conversationVM.loadConversations(for: ordersVM.orders) } }
                    )
                } else {
                    conversationList
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await conversationVM.loadConversations(for: ordersVM.orders) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search conversations")
            .refreshable {
                await conversationVM.loadConversations(for: ordersVM.orders)
            }
            .navigationDestination(item: $conversationVM.activeConversation) { conversation in
                ConversationView(
                    conversation: conversation,
                    conversationVM: conversationVM,
                    ordersVM: ordersVM
                )
            }
        }
    }

    private var conversationList: some View {
        List {
            ForEach(filteredConversations) { conversation in
                ConversationRowView(conversation: conversation) {
                    conversationVM.openConversation(conversation)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        // Archive conversation (local state)
                    } label: {
                        Label("Archive", systemImage: "archivebox.fill")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        conversationVM.openConversation(conversation)
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
                    }
                    .tint(.ebayBlue)
                }
            }
        }
        .listStyle(.plain)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct ConversationRowView: View {
    let conversation: Conversation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                buyerAvatar
                conversationInfo
                Spacer()
                trailingSection
            }
            .padding(14)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var buyerAvatar: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(avatarGradient)
                    .frame(width: 54, height: 54)
                Text(conversation.buyer.username.initials)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            if conversation.orderStatus == .fulfilled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.ebayGreen)
                    .background(Circle().fill(.white).padding(-2))
            }
        }
    }

    private var avatarGradient: LinearGradient {
        let colors: [[Color]] = [
            [.blue, .purple],
            [.green, .teal],
            [.orange, .red],
            [.indigo, .blue],
            [.pink, .purple]
        ]
        let index = abs(conversation.buyer.username.hashValue) % colors.count
        return LinearGradient(colors: colors[index], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var conversationInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(conversation.buyer.username)
                    .font(.subheadline)
                    .fontWeight(conversation.unreadCount > 0 ? .bold : .semibold)
                    .lineLimit(1)
            }

            Text(conversation.itemTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(conversation.preview)
                .font(.caption)
                .foregroundStyle(conversation.unreadCount > 0 ? .primary : .secondary)
                .fontWeight(conversation.unreadCount > 0 ? .medium : .regular)
                .lineLimit(2)
        }
    }

    private var trailingSection: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(conversation.lastActivity.conversationTimestamp)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .padding(.horizontal, 4)
                    .background(Color.ebayBlue)
                    .clipShape(Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            orderStatusDot
        }
    }

    private var orderStatusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }

    private var statusColor: Color {
        switch conversation.orderStatus {
        case .fulfilled: return .ebayGreen
        case .inProgress: return .orange
        case .notStarted: return .ebayRed
        }
    }
}
