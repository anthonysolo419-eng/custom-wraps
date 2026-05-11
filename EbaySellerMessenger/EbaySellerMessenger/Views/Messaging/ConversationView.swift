import SwiftUI

struct ConversationView: View {
    let conversation: Conversation
    @ObservedObject var conversationVM: ConversationViewModel
    @ObservedObject var ordersVM: OrdersViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var scrollProxy: ScrollViewProxy?
    @FocusState private var isInputFocused: Bool

    var displayConversation: Conversation {
        conversationVM.activeConversation ?? conversation
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                orderInfoBanner
                messageThread
                MessageInputView(
                    conversationVM: conversationVM,
                    conversation: displayConversation,
                    isFocused: $isInputFocused
                )
            }
        }
        .navigationTitle(conversation.buyer.username)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar { toolbarContent }
        .sheet(isPresented: $conversationVM.showCouponPicker) {
            CouponPickerView(
                coupons: conversationVM.availableCoupons,
                onSelect: { conversationVM.insertCoupon($0) }
            )
        }
        .onDisappear { conversationVM.closeConversation() }
        .onAppear {
            scrollToBottom()
        }
        .alert("Error", isPresented: .constant(conversationVM.error != nil)) {
            Button("OK") { conversationVM.error = nil }
        } message: {
            Text(conversationVM.error ?? "")
        }
    }

    private var orderInfoBanner: some View {
        HStack(spacing: 10) {
            if let imageUrl = conversation.itemImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.itemTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    statusBadge
                    Text(conversation.orderTotal)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(Divider(), alignment: .bottom)
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch conversation.orderStatus {
        case .fulfilled: return "Shipped"
        case .inProgress: return "Processing"
        case .notStarted: return "Awaiting"
        }
    }

    private var statusColor: Color {
        switch conversation.orderStatus {
        case .fulfilled: return .ebayGreen
        case .inProgress: return .orange
        case .notStarted: return .ebayRed
        }
    }

    private var messageThread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    if displayConversation.messages.isEmpty {
                        emptyThreadPlaceholder
                    } else {
                        messagesWithDateHeaders
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .onAppear { scrollProxy = proxy }
            .onChange(of: displayConversation.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private var emptyThreadPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.4))
            Text("Start the conversation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Send a message to \(conversation.buyer.username)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var messagesWithDateHeaders: some View {
        ForEach(groupedMessages, id: \.date) { group in
            Section {
                ForEach(group.messages) { message in
                    MessageBubbleView(message: message)
                        .id(message.id)
                }
            } header: {
                dateSeparator(for: group.date)
            }
        }
    }

    private func dateSeparator(for date: Date) -> some View {
        Text(date.conversationTimestamp)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(UIColor.systemBackground).opacity(0.8))
            .clipShape(Capsule())
            .padding(.vertical, 8)
    }

    private var groupedMessages: [(date: Date, messages: [Message])] {
        let messages = displayConversation.messages
        var groups: [(date: Date, messages: [Message])] = []
        var current: [Message] = []
        var currentDate: Date?

        for message in messages {
            let day = Calendar.current.startOfDay(for: message.creationDate)
            if let cd = currentDate, Calendar.current.isDate(cd, inSameDayAs: day) {
                current.append(message)
            } else {
                if !current.isEmpty, let cd = currentDate {
                    groups.append((date: cd, messages: current))
                }
                current = [message]
                currentDate = day
            }
        }
        if !current.isEmpty, let cd = currentDate {
            groups.append((date: cd, messages: current))
        }
        return groups
    }

    private func scrollToBottom(proxy: ScrollViewProxy? = nil) {
        let p = proxy ?? scrollProxy
        if let lastId = displayConversation.messages.last?.id {
            withAnimation(.easeOut(duration: 0.3)) {
                p?.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    Task { await conversationVM.refreshConversation(conversation, orders: ordersVM.orders) }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                Button {
                    conversationVM.showCouponPicker = true
                } label: {
                    Label("Send Coupon", systemImage: "tag.fill")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}
