import Foundation

final class MessagingService {
    static let shared = MessagingService()
    private init() {}

    private let api = EbayAPIService.shared

    // MARK: - Fetch Messages

    func fetchConversations(for orders: [Order]) async -> [Conversation] {
        var conversations: [Conversation] = []
        await withTaskGroup(of: Conversation?.self) { group in
            for order in orders {
                group.addTask {
                    await self.buildConversation(for: order)
                }
            }
            for await conversation in group {
                if let conv = conversation {
                    conversations.append(conv)
                }
            }
        }
        return conversations.sorted { $0.lastActivity > $1.lastActivity }
    }

    func fetchMessages(for order: Order) async throws -> [Message] {
        let buyerUsername = order.buyer.username
        let itemId = order.lineItems.first.map { _ in order.legacyOrderId ?? order.id } ?? order.id

        let response = try await api.request(
            path: "/sell/message/v1/topic/\(itemId)/message",
            queryItems: [
                URLQueryItem(name: "transaction_id", value: order.legacyOrderId ?? order.id)
            ],
            responseType: MessageThreadResponse.self
        )

        return response.messages?.map { thread in
            mapToMessage(thread: thread, buyerUsername: buyerUsername, orderId: order.id)
        } ?? []
    }

    func sendMessage(
        to order: Order,
        text: String,
        subject: String? = nil
    ) async throws {
        let itemId = order.legacyOrderId ?? order.id
        let payload = MessageSendPayload(
            body: text,
            itemId: itemId,
            recipientId: order.buyer.username,
            subject: subject ?? "Re: Order \(order.id)"
        )

        try await api.requestVoid(
            path: "/sell/message/v1/topic/\(itemId)/message",
            method: .post,
            body: payload
        )
    }

    func sendBulkMessages(
        to orders: [Order],
        text: String,
        subject: String? = nil
    ) async -> BulkSendResult {
        var succeeded: [String] = []
        var failed: [(orderId: String, error: String)] = []

        await withTaskGroup(of: (String, Error?).self) { group in
            for order in orders {
                group.addTask {
                    do {
                        try await self.sendMessage(to: order, text: text, subject: subject)
                        return (order.id, nil)
                    } catch {
                        return (order.id, error)
                    }
                }
            }
            for await (orderId, error) in group {
                if let error = error {
                    failed.append((orderId: orderId, error: error.localizedDescription))
                } else {
                    succeeded.append(orderId)
                }
            }
        }

        return BulkSendResult(succeeded: succeeded, failed: failed)
    }

    func markAsRead(messageId: String, topicId: String) async throws {
        try await api.requestVoid(
            path: "/sell/message/v1/topic/\(topicId)/message/\(messageId)/mark_as_read",
            method: .post
        )
    }

    // MARK: - Private Helpers

    private func buildConversation(for order: Order) async -> Conversation? {
        let messages = (try? await fetchMessages(for: order)) ?? []
        let lastMessage = messages.sorted { $0.creationDate > $1.creationDate }.first
        let unread = messages.filter { !$0.isRead && !$0.isFromSeller }.count

        return Conversation(
            id: order.id,
            orderId: order.id,
            buyer: order.buyer,
            itemTitle: order.firstItemTitle,
            itemImageUrl: order.firstItemImageUrl,
            messages: messages.sorted { $0.creationDate < $1.creationDate },
            lastMessage: lastMessage,
            unreadCount: unread,
            orderStatus: order.orderFulfillmentStatus,
            orderTotal: order.totalAmount
        )
    }

    private func mapToMessage(thread: MessageThread, buyerUsername: String, orderId: String) -> Message {
        let isFromSeller = thread.sender?.role == "SELLER"
        return Message(
            id: thread.messageId ?? UUID().uuidString,
            itemId: orderId,
            senderId: thread.sender?.userId ?? "",
            senderName: isFromSeller ? "You" : buyerUsername,
            recipientId: isFromSeller ? buyerUsername : "seller",
            subject: thread.subject,
            text: thread.text ?? "",
            creationDate: thread.timestamp.flatMap { Date.fromEbayString($0) } ?? Date(),
            isRead: thread.read ?? true,
            messageType: isFromSeller ? .sent : .received,
            attachedCoupon: nil
        )
    }
}

// MARK: - Supporting Types

struct MessageThread: Codable {
    let messageId: String?
    let timestamp: String?
    let text: String?
    let sender: MessageParticipant?
    let recipients: [MessageParticipant]?
    let subject: String?
    let read: Bool?
}

struct MessageParticipant: Codable {
    let userId: String?
    let role: String?
}

struct MessageThreadResponse: Codable {
    let messages: [MessageThread]?
    let total: Int?
}

struct MessageSendPayload: Codable {
    let body: String
    let itemId: String
    let recipientId: String
    let subject: String

    enum CodingKeys: String, CodingKey {
        case body, subject
        case itemId = "item_id"
        case recipientId = "recipient_id"
    }
}

struct BulkSendResult {
    let succeeded: [String]
    let failed: [(orderId: String, error: String)]

    var successCount: Int { succeeded.count }
    var failureCount: Int { failed.count }
    var allSucceeded: Bool { failed.isEmpty }

    var summary: String {
        if allSucceeded {
            return "Messages sent to \(successCount) buyer\(successCount == 1 ? "" : "s")"
        }
        return "Sent \(successCount), failed \(failureCount)"
    }
}
