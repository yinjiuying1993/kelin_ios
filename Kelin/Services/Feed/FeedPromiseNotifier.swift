import Foundation
@preconcurrency import UserNotifications

enum FeedPromiseNotifier {
    static func schedule(feedID: UUID, remindAt: Date) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "约定到了")
            content.body = String(localized: "到了约定的时间")
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: remindAt
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier(for: feedID),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    static func replace(feedID: UUID, remindAt: Date) {
        remove(feedID: feedID)
        schedule(feedID: feedID, remindAt: remindAt)
    }

    static func remove(feedID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier(for: feedID)]
        )
    }

    private static func identifier(for feedID: UUID) -> String {
        "promise-\(feedID.uuidString.lowercased())"
    }
}
