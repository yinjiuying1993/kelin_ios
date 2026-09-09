import Foundation

enum EggSelectionOption: String, CaseIterable, Identifiable, Sendable {
    case warm
    case cold
    case variable

    var id: String { rawValue }

    var eggType: EggType {
        switch self {
        case .warm:
            .warm
        case .cold:
            .cold
        case .variable:
            .wild
        }
    }

    var title: String {
        switch self {
        case .warm:
            String(localized: "暖")
        case .cold:
            String(localized: "冷")
        case .variable:
            String(localized: "不定")
        }
    }

    var subtitle: String {
        switch self {
        case .warm:
            String(localized: "更愿意靠近")
        case .cold:
            String(localized: "更容易带刺")
        case .variable:
            String(localized: "交给前五句话")
        }
    }

    var hint: String {
        switch self {
        case .warm:
            String(localized: "它将以柔和包容的姿态靠近你")
        case .cold:
            String(localized: "它习惯保持距离，需要更耐心的回应")
        case .variable:
            String(localized: "随最初的交谈流转，不可预知")
        }
    }

    var accentColor: UInt32 {
        switch self {
        case .warm:
            0xF2B86B
        case .cold:
            0x73B8D4
        case .variable:
            0x8C7CFF
        }
    }

    var glowOpacity: Double {
        switch self {
        case .warm, .cold:
            0.2
        case .variable:
            0.25
        }
    }
}

enum HatchDefaults {
    static let placeholderSpiritName = String(localized: "未名")
}
