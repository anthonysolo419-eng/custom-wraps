import Foundation
import SwiftUI

extension Date {
    var conversationTimestamp: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if calendar.dateComponents([.day], from: self, to: Date()).day ?? 0 < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: self)
        }
    }

    static func fromEbayString(_ string: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss'Z'"
        ]
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }
}

extension Color {
    static let messageBubbleSent = Color("MessageBubbleSent", bundle: nil)
    static let messageBubbleReceived = Color("MessageBubbleReceived", bundle: nil)

    static var ebayBlue: Color { Color(red: 0.22, green: 0.49, blue: 0.96) }
    static var ebayRed: Color { Color(red: 0.91, green: 0.16, blue: 0.16) }
    static var ebayYellow: Color { Color(red: 1.0, green: 0.73, blue: 0.0) }
    static var ebayGreen: Color { Color(red: 0.13, green: 0.71, blue: 0.29) }

    static var sentBubble: Color { Color(red: 0.22, green: 0.49, blue: 0.96) }
    static var receivedBubble: Color { Color(UIColor.secondarySystemBackground) }
    static var backgroundPrimary: Color { Color(UIColor.systemBackground) }
    static var backgroundSecondary: Color { Color(UIColor.secondarySystemBackground) }
}

extension View {
    func cardStyle() -> some View {
        self
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    func shimmerEffect() -> some View {
        self.redacted(reason: .placeholder)
    }
}

extension String {
    var initials: String {
        let words = self.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(self.prefix(2)).uppercased()
    }
}
