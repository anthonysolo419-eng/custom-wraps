import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleNewMessageNotification(buyerName: String, preview: String, orderId: String) {
        let content = UNMutableNotificationContent()
        content.title = "New message from \(buyerName)"
        content.body = preview
        content.sound = .default
        content.badge = 1
        content.userInfo = ["orderId": orderId, "type": "new_message"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "msg_\(orderId)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }

    func clearNotifications(for orderId: String) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let ids = notifications
                .filter { ($0.request.content.userInfo["orderId"] as? String) == orderId }
                .map { $0.request.identifier }
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
        }
    }
}
