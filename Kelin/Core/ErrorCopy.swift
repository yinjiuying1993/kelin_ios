import Foundation

struct ErrorCopy: Equatable, Sendable {
    let title: String
    let message: String
    let recoveryActionTitle: String?

    static let asrEmptyResult = String(localized: "没听清，再说一次")
    static let recordingTooShort = String(localized: "说得太短了")
    static let ttsQuotaExceeded = String(localized: "今天先看字吧")
    static let unreliableSource = String(localized: "这件事我还不知道")
    static let sightRejected = String(localized: "这件它收不下")

    static func app(_ error: AppError) -> ErrorCopy {
        switch error {
        case .unauthenticated:
            ErrorCopy(
                title: String(localized: "需要重新连接"),
                message: String(localized: "身份已失效，请重新进入。"),
                recoveryActionTitle: String(localized: "重新进入")
            )
        case .networkUnavailable:
            ErrorCopy(
                title: String(localized: "连不上"),
                message: String(localized: "连不上，房间还在"),
                recoveryActionTitle: String(localized: "再试一次")
            )
        case .timedOut:
            ErrorCopy(
                title: String(localized: "等得有点久"),
                message: String(localized: "这次没有及时回应。"),
                recoveryActionTitle: String(localized: "再试一次")
            )
        case .invalidInput:
            ErrorCopy(
                title: String(localized: "内容不太对"),
                message: String(localized: "检查后再试一次。"),
                recoveryActionTitle: nil
            )
        case .permissionDenied:
            ErrorCopy(
                title: String(localized: "还没有权限"),
                message: String(localized: "请在系统设置中允许这项功能。"),
                recoveryActionTitle: String(localized: "去设置")
            )
        case .rateLimited:
            ErrorCopy(
                title: String(localized: "操作太快了"),
                message: String(localized: "稍等一会儿再试。"),
                recoveryActionTitle: nil
            )
        case let .quotaExceeded(kind):
            ErrorCopy(
                title: String(localized: "今天先到这里吧"),
                message: kind == .tts
                    ? ttsQuotaExceeded
                    : String(localized: "今天的使用次数已经用完。"),
                recoveryActionTitle: nil
            )
        case .modelUnavailable:
            ErrorCopy(
                title: String(localized: "暂时没有回应"),
                message: String(localized: "它这会儿说不出话"),
                recoveryActionTitle: String(localized: "再试一次")
            )
        case .moderationRejected:
            ErrorCopy(
                title: String(localized: "没有收下"),
                message: sightRejected,
                recoveryActionTitle: nil
            )
        case .notFound:
            ErrorCopy(
                title: String(localized: "没有找到"),
                message: String(localized: "这项内容可能已经不存在。"),
                recoveryActionTitle: nil
            )
        case .conflict:
            ErrorCopy(
                title: String(localized: "内容已经变化"),
                message: String(localized: "刷新后再试一次。"),
                recoveryActionTitle: String(localized: "刷新")
            )
        case .decoding:
            ErrorCopy(
                title: String(localized: "暂时无法显示"),
                message: String(localized: "收到的内容无法识别。"),
                recoveryActionTitle: String(localized: "再试一次")
            )
        case .cancelled:
            ErrorCopy(
                title: String(localized: "已取消"),
                message: String(localized: "这次操作没有继续。"),
                recoveryActionTitle: nil
            )
        case .unknown:
            ErrorCopy(
                title: String(localized: "出了点问题"),
                message: String(localized: "请稍后再试。"),
                recoveryActionTitle: String(localized: "再试一次")
            )
        }
    }

    static func configuration(_ error: AppConfigError) -> ErrorCopy {
        ErrorCopy(
            title: String(localized: "应用配置错误"),
            message: String(localized: "缺少或无法识别必要配置，请联系开发者。"),
            recoveryActionTitle: nil
        )
    }
}
