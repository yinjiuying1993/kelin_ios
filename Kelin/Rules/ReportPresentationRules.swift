import Foundation

enum ReportPresentationRules {
    static func screenTitle() -> String {
        String(localized: "七日鉴定")
    }

    static func lockedTitle() -> String {
        String(localized: "尚未完成初度鉴定")
    }

    static func lockedBody() -> String {
        String(localized: "它在你说过的话里慢慢长成模样。满 7 天且完成 10 轮有效对话后点亮。")
    }

    static func generatingTitle() -> String {
        String(localized: "鉴定图纸凝结中")
    }

    static func shareLocked() -> String {
        String(localized: "未达标状态不可分享")
    }

    static func talkTitle(spiritName: String) -> String {
        String(localized: "去和\(spiritName)说话")
    }

    static func signatureMissing() -> String {
        String(localized: "签名句还没写好")
    }

    static func daysRemaining(_ value: Int) -> String {
        String(localized: "还差 \(value) 天")
    }

    static func roundsRemaining(_ value: Int) -> String {
        String(localized: "还差 \(value) 轮")
    }
}
