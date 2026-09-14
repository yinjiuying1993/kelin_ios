import Foundation

struct SocialPeerFixture: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let kind: SocialPeerKind
    let symbol: String
    let tint: SocialPeerTint
}

enum SocialPeerTint: Equatable, Sendable {
    case accent
    case warm
    case cold
}

struct SocialPostcardFixture: Equatable, Sendable, Identifiable {
    let id: UUID
    let senderTitle: String
    let timeLabel: String
    let body: String
    var isUnread: Bool
}

enum SocialDraftFixtures {
    static let emptyVisitsLabel = String(localized: "暂无记录")
    static let latestVisitsTitle = String(localized: "最新来访")
    static let lastNightTitle = String(localized: "昨夜")
    static let friendsSectionTitle = String(localized: "认识的灵")
    static let allowVisitsTitle = String(localized: "允许来访")
    static let allowVisitsSubtitle = String(localized: "允许其他灵体留下足迹与信件")
    static let enterFriendCodeTitle = String(localized: "输入好友邀请码")
    static let postcardReplyTitle = String(localized: "回应")

    static let npcPeers: [SocialPeerFixture] = [
        SocialPeerFixture(
            id: "npc.mist",
            title: String(localized: "雾里的那只"),
            subtitle: String(localized: "偶遇于雨夜 · 隐于雾气之中"),
            kind: .npc,
            symbol: "aqi.medium",
            tint: .accent
        ),
        SocialPeerFixture(
            id: "npc.lamp",
            title: String(localized: "守灯的那只"),
            subtitle: String(localized: "偶遇于街角 · 静候昏黄灯晕"),
            kind: .npc,
            symbol: "light.max",
            tint: .warm
        ),
        SocialPeerFixture(
            id: "npc.overcast",
            title: String(localized: "阴天收集者"),
            subtitle: String(localized: "偶遇于薄暮 · 收藏静默云影"),
            kind: .npc,
            symbol: "cloud",
            tint: .cold
        ),
    ]

    static let friendPeers: [SocialPeerFixture] = [
        SocialPeerFixture(
            id: "friend.lamp",
            title: String(localized: "守灯的那只"),
            subtitle: String(localized: "已静静停留 3 天"),
            kind: .friend,
            symbol: "light.max",
            tint: .warm
        ),
        SocialPeerFixture(
            id: "friend.overcast",
            title: String(localized: "阴天收集者"),
            subtitle: String(localized: "刚刚路过"),
            kind: .friend,
            symbol: "cloud",
            tint: .cold
        ),
    ]

    static let unreadPostcard = SocialPostcardFixture(
        id: UUID(uuidString: "40000000-0000-4000-8000-000000000001")!,
        senderTitle: String(localized: "雾里的那只"),
        timeLabel: "02:14",
        body: String(localized: "“它们家太亮，我站在门外看了一会儿。”"),
        isUnread: true
    )
}
