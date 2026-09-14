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
        case .invalidCursor:
            ErrorCopy(
                title: String(localized: "记录位置失效"),
                message: String(localized: "从最新一页重新看。"),
                recoveryActionTitle: String(localized: "重新加载")
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
        case let .quotaExceeded(kind, resetAt):
            ErrorCopy(
                title: String(localized: "今天先到这里吧"),
                message: quotaMessage(kind: kind, resetAt: resetAt),
                recoveryActionTitle: nil
            )
        case .asrEmptyResult:
            ErrorCopy(
                title: String(localized: "没听清"),
                message: asrEmptyResult,
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
        case .selfFriendNotAllowed:
            ErrorCopy(
                title: String(localized: "不能加自己"),
                message: String(localized: "邀请码不对，或不能填自己的"),
                recoveryActionTitle: nil
            )
        case .accountDeletePending:
            ErrorCopy(
                title: String(localized: "注销已在进行"),
                message: String(localized: "账号正在删除，不要换一次再提。"),
                recoveryActionTitle: nil
            )
        case .reportLineUnavailable:
            ErrorCopy(
                title: String(localized: "签名句还没写好"),
                message: String(localized: "签名句暂时写不了，可稍后再试。"),
                recoveryActionTitle: String(localized: "再试一次")
            )
        case .spiritNotLost:
            ErrorCopy(
                title: String(localized: "现在不用找回"),
                message: String(localized: "它还在，不用叫它回来。"),
                recoveryActionTitle: nil
            )
        case .recallSourceInvalid:
            ErrorCopy(
                title: String(localized: "这次带不回来"),
                message: String(localized: "换食物找回，或换一条可用见闻。"),
                recoveryActionTitle: nil
            )
        case .sightUploadUnavailable:
            ErrorCopy(
                title: String(localized: "见闻还没传上去"),
                message: String(localized: "服务端给的上传地址这台设备到不了，先用地点见闻，或等存储签发可访问的地址。"),
                recoveryActionTitle: nil
            )
        case .idempotencyConflict:
            ErrorCopy(
                title: String(localized: "这次请求对不上"),
                message: String(localized: "同一操作换了内容，稍后再试。"),
                recoveryActionTitle: nil
            )
        case .idempotencyInProgress:
            ErrorCopy(
                title: String(localized: "操作太快了"),
                message: String(localized: "稍等一会儿再试。"),
                recoveryActionTitle: nil
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

    private static func quotaMessage(kind: QuotaKind, resetAt: Date?) -> String {
        let base = (kind == .tts || kind == .asr)
            ? ttsQuotaExceeded
            : String(localized: "今天的使用次数已经用完。")
        guard let resetAt else {
            return base
        }

        let formatted = resetAt.formatted(
            Date.FormatStyle(date: .numeric, time: .shortened)
                .locale(Locale(identifier: "zh_CN"))
        )
        return "\(base) \(String(localized: "下次重置时间："))\(formatted)"
    }

    static func configuration(_ error: AppConfigError) -> ErrorCopy {
        ErrorCopy(
            title: String(localized: "应用配置错误"),
            message: String(localized: "缺少或无法识别必要配置，请联系开发者。"),
            recoveryActionTitle: nil
        )
    }
}
