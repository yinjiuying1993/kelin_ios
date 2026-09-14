import Foundation

enum MemoryFilter: String, CaseIterable, Equatable, Sendable {
    case all
    case relationship
    case knowledge
    case speech
    case sight

    var title: String {
        switch self {
        case .all:
            String(localized: "全部")
        case .relationship:
            String(localized: "偏好与关系")
        case .knowledge:
            String(localized: "知识")
        case .speech:
            String(localized: "口癖")
        case .sight:
            String(localized: "见闻")
        }
    }
}

enum MemoryDaySection: String, Equatable, Sendable, CaseIterable {
    case today
    case yesterday
    case thisWeek
    case earlier

    var title: String {
        switch self {
        case .today:
            String(localized: "今天")
        case .yesterday:
            String(localized: "昨天")
        case .thisWeek:
            String(localized: "本周")
        case .earlier:
            String(localized: "更早")
        }
    }
}

enum MemoryTypeTint: Equatable, Sendable {
    case accent
    case cold
    case warm
    case success
    case secondary
}

struct MemoryTimelineItem: Equatable, Sendable, Identifiable {
    let memory: MemorySummary
    let typeTitle: String
    let impactTitle: String
    let symbolName: String
    let tint: MemoryTypeTint

    var id: UUID { memory.id }
}

struct MemoryDayGroup: Equatable, Sendable, Identifiable {
    let section: MemoryDaySection
    let items: [MemoryTimelineItem]

    var id: MemoryDaySection { section }
}

enum MemoryPresentationRules {
    static let relationshipTypes: Set<String> = ["preference", "relation", "emotion"]

    static func matches(_ memory: MemorySummary, filter: MemoryFilter) -> Bool {
        guard isListable(memory) else {
            return false
        }

        switch filter {
        case .all:
            return true
        case .relationship:
            return relationshipTypes.contains(memory.type)
        case .knowledge, .speech, .sight:
            return memory.type == filter.rawValue
        }
    }

    static func isListable(_ memory: MemorySummary) -> Bool {
        memory.status != "sealed" && memory.status != "deleted"
    }

    static func visibleItems(
        from memories: [MemorySummary],
        filter: MemoryFilter
    ) -> [MemorySummary] {
        memories
            .filter { matches($0, filter: filter) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    static func timelineItem(from memory: MemorySummary) -> MemoryTimelineItem {
        let style = typeStyle(memory.type)
        return MemoryTimelineItem(
            memory: memory,
            typeTitle: style.title,
            impactTitle: style.impact,
            symbolName: style.symbolName,
            tint: style.tint
        )
    }

    static func daySection(
        for date: Date,
        now: Date,
        calendar: Calendar
    ) -> MemoryDaySection {
        if calendar.isDate(date, inSameDayAs: now) {
            return .today
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return .yesterday
        }
        if let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
           date >= weekStart {
            return .thisWeek
        }
        return .earlier
    }

    static func groups(
        from memories: [MemorySummary],
        filter: MemoryFilter,
        now: Date,
        calendar: Calendar
    ) -> [MemoryDayGroup] {
        let items = visibleItems(from: memories, filter: filter).map(timelineItem(from:))
        var buckets: [MemoryDaySection: [MemoryTimelineItem]] = [:]
        for item in items {
            let section = daySection(for: item.memory.createdAt, now: now, calendar: calendar)
            buckets[section, default: []].append(item)
        }

        return MemoryDaySection.allCases.compactMap { section in
            guard let items = buckets[section], !items.isEmpty else {
                return nil
            }
            return MemoryDayGroup(section: section, items: items)
        }
    }

    static func statusTitle(_ status: String) -> String {
        switch status {
        case "sealed":
            String(localized: "已封存")
        case "deleted":
            String(localized: "已删除")
        default:
            String(localized: "还在用")
        }
    }

    static func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func typeStyle(_ type: String) -> (title: String, impact: String, symbolName: String, tint: MemoryTypeTint) {
        switch type {
        case "preference":
            (String(localized: "偏好"), String(localized: "称呼"), "diamond.fill", .cold)
        case "relation":
            (String(localized: "关系"), String(localized: "关系"), "person.2.fill", .accent)
        case "emotion":
            (String(localized: "心情"), String(localized: "心情"), "heart.fill", .accent)
        case "knowledge":
            (String(localized: "知识"), String(localized: "共学书架"), "sparkles", .success)
        case "speech":
            (String(localized: "口癖"), String(localized: "说话方式"), "text.quote", .accent)
        case "sight":
            (String(localized: "见闻"), String(localized: "窗台摆件"), "eye.fill", .warm)
        default:
            (type, String(localized: "痕迹"), "circle.fill", .secondary)
        }
    }
}
