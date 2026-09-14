import Foundation

enum SettingsDangerAction: Equatable, Sendable {
    case clearAllMemories
    case deleteAccount
}

enum SettingsPresentationRules {
    static let draftVersion = "V0.9.4"
    static let sampleInviteCode = "ABCD2345"
    static let defaultDNDStart = "23:00"
    static let defaultDNDEnd = "08:00"
    static let nameMaxLength = 20

    static func screenTitle() -> String {
        String(localized: "设置")
    }

    static func spiritGroupTitle() -> String {
        String(localized: "精灵")
    }

    static func companionGroupTitle() -> String {
        String(localized: "陪伴")
    }

    static func socialGroupTitle() -> String {
        String(localized: "社交")
    }

    static func dataGroupTitle() -> String {
        String(localized: "数据")
    }

    static func aboutGroupTitle() -> String {
        String(localized: "关于")
    }

    static func renameTitle() -> String {
        String(localized: "改名")
    }

    static func spiritIDTitle() -> String {
        String(localized: "精灵 ID")
    }

    static func inviteCodeTitle() -> String {
        String(localized: "邀请码")
    }

    static func ttsTitle() -> String {
        String(localized: "自动语音播报")
    }

    static func notificationTitle() -> String {
        String(localized: "通知")
    }

    static func dndTitle() -> String {
        String(localized: "勿扰时段")
    }

    static func locationWeatherTitle() -> String {
        String(localized: "定位天气")
    }

    static func remoteSearchTitle() -> String {
        String(localized: "联网查询")
    }

    static func visitTitle() -> String {
        String(localized: "允许来访")
    }

    static func friendsTitle() -> String {
        String(localized: "好友管理")
    }

    static func memoryCenterTitle() -> String {
        String(localized: "记忆中心")
    }

    static func clearAllTitle() -> String {
        String(localized: "清除全部记忆")
    }

    static func deleteAccountTitle() -> String {
        String(localized: "注销数据")
    }

    static func aiDisclosureTitle() -> String {
        String(localized: "它是人工智能")
    }

    static func versionTitle() -> String {
        String(localized: "当前版本")
    }

    static func footerCopy() -> String {
        String(localized: "相处，会在身上留下痕迹")
    }

    static func laterTitle() -> String {
        String(localized: "暂时不用")
    }

    static func goSettingsTitle() -> String {
        String(localized: "去设置")
    }

    static func confirmTitle(for action: SettingsDangerAction) -> String {
        switch action {
        case .clearAllMemories:
            String(localized: "清除所有记忆？")
        case .deleteAccount:
            String(localized: "删除这只灵？")
        }
    }

    static func confirmMessage(for action: SettingsDangerAction) -> String {
        switch action {
        case .clearAllMemories:
            String(localized: "口癖、偏好、见闻和知识都会消失。")
        case .deleteAccount:
            String(localized: "所有记忆、消息和关系都会被删除。")
        }
    }

    static func confirmAction(for action: SettingsDangerAction) -> String {
        switch action {
        case .clearAllMemories:
            String(localized: "全部清除")
        case .deleteAccount:
            String(localized: "删除数据")
        }
    }

    static func aiDisclosureBody() -> String {
        String(localized: "刻灵是一款人工智能陪伴产品。你在应用中的对话与互动会用于塑造精灵的性格与记忆。继续使用即表示你已阅读并理解本说明。")
    }

    static func displaySpiritID(_ id: UUID) -> String {
        let hex = id.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        return "KL-\(hex.prefix(4))…\(hex.suffix(4))"
    }

    static func formatDND(start: String, end: String) -> String {
        "\(start) – \(end)"
    }

    static func hhmm(from date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    static func date(fromHHMM raw: String, calendar: Calendar = .current, now: Date = Date()) -> Date {
        let parts = raw.split(separator: ":")
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = parts.first.flatMap { Int($0) } ?? 23
        components.minute = parts.dropFirst().first.flatMap { Int($0) } ?? 0
        return calendar.date(from: components) ?? now
    }

    static func validateName(_ raw: String) throws -> String {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= nameMaxLength else {
            throw AppError.invalidInput
        }
        return name
    }
}
