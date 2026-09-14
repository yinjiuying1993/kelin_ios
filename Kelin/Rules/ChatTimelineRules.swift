import Foundation

enum ChatTimelineItem: Equatable, Identifiable, Sendable {
    case dayDivider(String)
    case message(ChatMessage)

    var id: String {
        switch self {
        case let .dayDivider(label):
            "divider-\(label)"
        case let .message(message):
            message.id.uuidString
        }
    }
}

enum ChatTimelineRules {
    static func timelineItems(
        from messages: [ChatMessage],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ChatTimelineItem] {
        let sorted = ChatHistoryRules.stableSort(messages)
        var items: [ChatTimelineItem] = []
        var previousDay: DateComponents?

        for message in sorted {
            let day = calendar.dateComponents([.year, .month, .day], from: message.createdAt)
            if day != previousDay {
                if let label = dayDividerLabel(for: message.createdAt, now: now, calendar: calendar) {
                    items.append(.dayDivider(label))
                }
                previousDay = day
            }
            items.append(.message(message))
        }

        return items
    }

    static func dayDividerLabel(
        for date: Date,
        now: Date,
        calendar: Calendar = .current
    ) -> String? {
        if calendar.isDateInToday(date) {
            return nil
        }

        if calendar.isDateInYesterday(date) {
            let hour = calendar.component(.hour, from: date)
            if hour >= 18 || hour < 6 {
                return String(localized: "昨天夜里")
            }
            if hour < 12 {
                return String(localized: "昨天早上")
            }
            return String(localized: "昨天下午")
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = String(localized: "M月d日")
        return formatter.string(from: date)
    }
}
