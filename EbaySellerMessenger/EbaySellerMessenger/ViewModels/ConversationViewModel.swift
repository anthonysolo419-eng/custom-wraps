import Foundation
import SwiftUI

@MainActor
final class ConversationViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var activeConversation: Conversation?
    @Published var isLoading = false
    @Published var isSending = false
    @Published var error: String?
    @Published var sendSuccess: String?
    @Published var messageText = ""
    @Published var showCouponPicker = false
    @Published var showBulkMessage = false
    @Published var bulkMessageText = ""
    @Published var bulkMessageSubject = ""
    @Published var availableCoupons: [Coupon] = Coupon.samples

    private let messagingService = MessagingService.shared
    private var pollingTask: Task<Void, Never>?

    func loadConversations(for orders: [Order]) async {
        isLoading = true
        error = nil
        conversations = await messagingService.fetchConversations(for: orders)
        isLoading = false
    }

    func openConversation(_ conversation: Conversation) {
        activeConversation = conversation
        startPolling(for: conversation)
        NotificationService.shared.clearNotifications(for: conversation.orderId)
    }

    func closeConversation() {
        stopPolling()
        activeConversation = nil
    }

    func sendMessage(to conversation: Conversation) async {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let textToSend = messageText
        messageText = ""
        isSending = true
        error = nil

        do {
            let order = Order(
                id: conversation.orderId,
                legacyOrderId: nil,
                creationDate: Date(),
                lastModifiedDate: Date(),
                orderFulfillmentStatus: conversation.orderStatus,
                orderPaymentStatus: .paid,
                buyer: conversation.buyer,
                lineItems: [],
                pricingSummary: PricingSummary(
                    priceSubtotal: Amount(value: "0", currency: "USD"),
                    deliveryCost: nil,
                    total: Amount(value: conversation.orderTotal, currency: "USD")
                ),
                fulfillmentStartInstructions: nil
            )
            try await messagingService.sendMessage(to: order, text: textToSend)

            let newMessage = Message(
                id: UUID().uuidString,
                itemId: conversation.orderId,
                senderId: "seller",
                senderName: "You",
                recipientId: conversation.buyer.username,
                subject: nil,
                text: textToSend,
                creationDate: Date(),
                isRead: true,
                messageType: .sent,
                attachedCoupon: nil
            )
            appendMessage(newMessage, to: conversation.id)
        } catch {
            self.error = error.localizedDescription
            messageText = textToSend
        }
        isSending = false
    }

    func insertCoupon(_ coupon: Coupon) {
        let couponText = coupon.insertableText
        if messageText.isEmpty {
            messageText = couponText
        } else {
            messageText += "\n\n" + couponText
        }
        showCouponPicker = false
    }

    func sendBulkMessage(to orders: [Order]) async {
        guard !bulkMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        error = nil
        sendSuccess = nil

        let result = await messagingService.sendBulkMessages(
            to: orders,
            text: bulkMessageText,
            subject: bulkMessageSubject.isEmpty ? nil : bulkMessageSubject
        )

        if result.allSucceeded {
            sendSuccess = result.summary
            bulkMessageText = ""
            bulkMessageSubject = ""
            showBulkMessage = false
        } else {
            sendSuccess = result.summary
            if result.failureCount > 0 {
                let failedIds = result.failed.map { $0.orderId }.joined(separator: ", ")
                error = "Failed for orders: \(failedIds)"
            }
        }
        isSending = false
    }

    func refreshConversation(_ conversation: Conversation, orders: [Order]) async {
        guard let order = orders.first(where: { $0.id == conversation.orderId }) else { return }
        if let messages = try? await messagingService.fetchMessages(for: order) {
            updateMessages(messages, for: conversation.id)
        }
    }

    var totalUnreadCount: Int { conversations.reduce(0) { $0 + $1.unreadCount } }

    // MARK: - Private

    private func appendMessage(_ message: Message, to conversationId: String) {
        if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[idx].messages.append(message)
            conversations[idx].lastMessage = message
        }
        if activeConversation?.id == conversationId {
            activeConversation?.messages.append(message)
            activeConversation?.lastMessage = message
        }
    }

    private func updateMessages(_ messages: [Message], for conversationId: String) {
        if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[idx].messages = messages.sorted { $0.creationDate < $1.creationDate }
            conversations[idx].lastMessage = messages.sorted { $0.creationDate > $1.creationDate }.first
            conversations[idx].unreadCount = messages.filter { !$0.isRead && !$0.isFromSeller }.count
        }
        if activeConversation?.id == conversationId {
            activeConversation?.messages = messages.sorted { $0.creationDate < $1.creationDate }
        }
    }

    private func startPolling(for conversation: Conversation) {
        stopPolling()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { break }
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
