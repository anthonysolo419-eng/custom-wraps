import Foundation

struct Message: Identifiable, Codable, Hashable {
    let id: String
    let itemId: String?
    let senderId: String
    let senderName: String
    let recipientId: String
    let subject: String?
    let text: String
    let creationDate: Date
    let isRead: Bool
    let messageType: MessageType
    let attachedCoupon: Coupon?

    var isFromSeller: Bool { messageType == .sent }

    var displayTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: creationDate, relativeTo: Date())
    }

    var fullTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
}

enum MessageType: String, Codable {
    case sent = "SENT"
    case received = "RECEIVED"
    case system = "SYSTEM"
}

struct Conversation: Identifiable, Codable, Hashable {
    let id: String
    let orderId: String
    let buyer: BuyerInfo
    let itemTitle: String
    let itemImageUrl: String?
    var messages: [Message]
    var lastMessage: Message?
    var unreadCount: Int
    let orderStatus: OrderFulfillmentStatus
    let orderTotal: String

    var lastActivity: Date {
        lastMessage?.creationDate ?? Date.distantPast
    }

    var preview: String {
        guard let last = lastMessage else { return "No messages yet" }
        let prefix = last.isFromSeller ? "You: " : ""
        let text = last.text
        let truncated = text.count > 60 ? String(text.prefix(60)) + "..." : text
        return prefix + truncated
    }
}

struct ConversationsResponse: Codable {
    let conversations: [Conversation]
}

struct SendMessageRequest: Codable {
    let body: String
    let itemId: String?
    let recipientId: String
    let subject: String?
    let type: String = "CONTACT_BUYER"
}

struct EbayMessageThread: Codable {
    let messageId: String?
    let timestamp: String?
    let text: String?
    let sender: EbayParticipant?
    let recipient: [EbayParticipant]?
    let subject: String?
    let read: Bool?
}

struct EbayParticipant: Codable {
    let userId: String?
    let role: String?
}

struct GetMemberMessagesResponse: Codable {
    let memberMessage: MemberMessageExchange?
}

struct MemberMessageExchange: Codable {
    let memberMessageExchangeArray: [MemberMessageExchangeItem]?
    let paginationResult: PaginationResult?
}

struct MemberMessageExchangeItem: Codable {
    let question: Question?
    let response: [Response]?
}

struct Question: Codable {
    let body: String?
    let creationDate: String?
    let messageId: String?
    let messageStatus: String?
    let read: Bool?
    let recipientUserID: String?
    let sender: Sender?
    let subject: String?
    let itemId: String?
}

struct Response: Codable {
    let body: String?
    let creationDate: String?
    let messageId: String?
    let sender: Sender?
}

struct Sender: Codable {
    let userID: String?
    let email: String?
}

struct PaginationResult: Codable {
    let totalNumberOfEntries: Int?
    let totalNumberOfPages: Int?
}
