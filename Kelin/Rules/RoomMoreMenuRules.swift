import Foundation

enum RoomMoreMenuDestination: Equatable, Sendable {
    case memory
    case pact
    case report
    case settings

    var route: Route {
        switch self {
        case .memory:
            .memory
        case .pact:
            .pact
        case .report:
            .report
        case .settings:
            .settings
        }
    }
}

enum RoomMoreMenuTint: Equatable, Sendable {
    case accent
    case cold
    case warm
    case secondary
}

struct RoomMoreMenuRow: Equatable, Sendable, Identifiable {
    let destination: RoomMoreMenuDestination
    let title: String
    let subtitle: String
    let symbolName: String
    let tint: RoomMoreMenuTint
    let showsIndicator: Bool

    var id: RoomMoreMenuDestination { destination }
}

struct RoomMoreMenuModel: Equatable, Sendable {
    static let drawerWidth: CGFloat = 292

    let spiritName: String
    let stageTitle: String
    let identityLine: String
    let inviteCode: String
    let companionDayText: String
    let rows: [RoomMoreMenuRow]
}

enum RoomMoreMenuRules {
    static func make(
        spirit: Spirit,
        weather: RoomWeather,
        latestMemories: [MemorySummary],
        activePact: PactSummary?,
        report: ReportSnapshot?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> RoomMoreMenuModel {
        RoomMoreMenuModel(
            spiritName: spirit.name,
            stageTitle: stageTitle(spirit.stage),
            identityLine: identityLine(weather: weather, scholarMarks: spirit.scholarMarks),
            inviteCode: spirit.inviteCode,
            companionDayText: companionDayText(
                createdAt: spirit.createdAt,
                now: now,
                calendar: calendar
            ),
            rows: [
                memoryRow(from: latestMemories),
                pactRow(from: activePact),
                reportRow(from: report),
                settingsRow,
            ]
        )
    }

    static func destinations(in model: RoomMoreMenuModel) -> [Route] {
        model.rows.map(\.destination.route)
    }

    private static func stageTitle(_ stage: SpiritStage) -> String {
        switch stage {
        case .whelp:
            String(localized: "幼灵")
        case .formed:
            String(localized: "成形期")
        case .awake:
            String(localized: "觉醒")
        }
    }

    private static func identityLine(weather: RoomWeather, scholarMarks: [String]) -> String {
        var parts = [weather.displayName]
        if !scholarMarks.isEmpty {
            parts.append(String(localized: "学者"))
        }
        return parts.joined(separator: " · ")
    }

    private static func companionDayText(createdAt: Date, now: Date, calendar: Calendar) -> String {
        let start = calendar.startOfDay(for: createdAt)
        let end = calendar.startOfDay(for: now)
        let days = max(calendar.dateComponents([.day], from: start, to: end).day ?? 0, 0) + 1
        return String(localized: "相伴第 \(days) 天")
    }

    private static func memoryRow(from memories: [MemorySummary]) -> RoomMoreMenuRow {
        let summaries = memories
            .filter { $0.status != "sealed" && $0.status != "deleted" }
            .prefix(3)
            .map(\.summary)
            .filter { !$0.isEmpty }

        return RoomMoreMenuRow(
            destination: .memory,
            title: String(localized: "记忆"),
            subtitle: summaries.isEmpty
                ? String(localized: "还没有刻痕")
                : summaries.joined(separator: " · "),
            symbolName: "brain.head.profile",
            tint: .accent,
            showsIndicator: !summaries.isEmpty
        )
    }

    private static func pactRow(from pact: PactSummary?) -> RoomMoreMenuRow {
        let subtitle: String
        if let pact {
            subtitle = [pact.theme, pact.title]
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
        } else {
            subtitle = String(localized: "这一周还没有约定要学的事")
        }

        return RoomMoreMenuRow(
            destination: .pact,
            title: String(localized: "共学"),
            subtitle: subtitle,
            symbolName: "book.closed.fill",
            tint: .cold,
            showsIndicator: false
        )
    }

    private static func reportRow(from report: ReportSnapshot?) -> RoomMoreMenuRow {
        RoomMoreMenuRow(
            destination: .report,
            title: String(localized: "七日鉴定"),
            subtitle: reportSubtitle(report),
            symbolName: "checkmark.seal",
            tint: .warm,
            showsIndicator: false
        )
    }

    private static func reportSubtitle(_ report: ReportSnapshot?) -> String {
        guard let report else {
            return String(localized: "还在长")
        }

        switch report.status {
        case .generating:
            return String(localized: "凝结中")
        case .partial:
            return String(localized: "还没写完")
        case .ready:
            return String(localized: "已经写好")
        case .failed:
            return String(localized: "这次没有写成")
        case .locked:
            if report.eligibility.daysRemaining > 0 {
                return String(localized: "还差 \(report.eligibility.daysRemaining) 天")
            }
            return String(localized: "还在长")
        }
    }

    private static var settingsRow: RoomMoreMenuRow {
        RoomMoreMenuRow(
            destination: .settings,
            title: String(localized: "设置"),
            subtitle: String(localized: "通知 · 播报 · 数据管理"),
            symbolName: "gearshape.fill",
            tint: .secondary,
            showsIndicator: false
        )
    }
}
