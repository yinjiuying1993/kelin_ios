import Foundation

enum RoomHotspot: String, CaseIterable, Equatable, Sendable {
    case spirit
    case eyeMark
    case scholarRune
    case paperNote
    case footprint
    case artifact
    case bookshelf
    case more
}

enum RoomMarkKind: String, Equatable, Sendable, Identifiable {
    case eye
    case scholar

    var id: String { rawValue }
}

enum RoomHotspotAction: Equatable, Sendable {
    case showSpiritDialogue
    case openChat
    case showMarkOrigin(RoomMarkKind)
    case showPaperNote
    case openSocial
    case showSightMemory
    case openPact
    case showMoreMenu
}

enum RoomPaperNoteTab: String, CaseIterable, Equatable, Sendable {
    case contract
    case study
    case visit
    case lost
}

enum RoomHotspotRules {
    static let minimumTouchTarget: CGFloat = 44
    static let dockEntryCount = 3
    static let spiritDialogueTimeout: TimeInterval = 3.2

    static let moreMenuDestinations: [Route] = [.memory, .pact, .report, .settings]

    static let dialogueLines = [
        String(localized: "……你在看我吗？"),
        String(localized: "房间里很安静，但有你在就很安心。"),
        String(localized: "肚子有一点空……想听你说说话。"),
        String(localized: "门口的脚步声，是你回来的声音吗？"),
    ]

    static func action(for hotspot: RoomHotspot) -> RoomHotspotAction {
        switch hotspot {
        case .spirit:
            .showSpiritDialogue
        case .eyeMark:
            .showMarkOrigin(.eye)
        case .scholarRune:
            .showMarkOrigin(.scholar)
        case .paperNote:
            .showPaperNote
        case .footprint:
            .openSocial
        case .artifact:
            .showSightMemory
        case .bookshelf:
            .openPact
        case .more:
            .showMoreMenu
        }
    }

    static func defaultPaperNoteTab(for letter: RoomLetter?) -> RoomPaperNoteTab {
        switch letter?.titleKey {
        case "room.letter.lost":
            .lost
        case "room.letter.visit":
            .visit
        case "room.letter.pact", "room.letter.care":
            .contract
        default:
            .contract
        }
    }

    static func accessibilityLabel(for hotspot: RoomHotspot) -> String {
        switch hotspot {
        case .spirit:
            String(localized: "精灵")
        case .eyeMark:
            String(localized: "眼光刻痕")
        case .scholarRune:
            String(localized: "学者纹")
        case .paperNote:
            String(localized: "地上字条")
        case .footprint:
            String(localized: "门口足迹")
        case .artifact:
            String(localized: "窗台物件：雨夜路灯")
        case .bookshelf:
            String(localized: "共学书架")
        case .more:
            String(localized: "更多")
        }
    }

    static func accessibilityHint(for hotspot: RoomHotspot) -> String {
        switch hotspot {
        case .spirit:
            String(localized: "轻点听它说话，再点进入对话")
        case .eyeMark, .scholarRune:
            String(localized: "查看形成原因")
        case .paperNote:
            String(localized: "打开约定、求知、串门或走丢信息")
        case .footprint:
            String(localized: "进入足迹")
        case .artifact:
            String(localized: "显示见闻记忆")
        case .bookshelf:
            String(localized: "进入共学或知识记忆")
        case .more:
            String(localized: "打开记忆、共学、鉴定和设置")
        }
    }
}

struct RoomSpiritTapSession: Equatable, Sendable {
    private(set) var tapCount = 0

    mutating func registerTap() -> RoomHotspotAction {
        tapCount += 1
        if tapCount >= 2 {
            tapCount = 0
            return .openChat
        }
        return .showSpiritDialogue
    }

    mutating func expireIfSingleTap() {
        if tapCount == 1 {
            tapCount = 0
        }
    }

    mutating func reset() {
        tapCount = 0
    }
}
