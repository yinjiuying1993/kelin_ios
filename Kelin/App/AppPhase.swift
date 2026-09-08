import Foundation

enum AppPhase: Equatable, Sendable {
    case launching
    case restoringSession
    case signingInAnonymously
    case requestingBootstrap
    case needsAgreement
    case needsEggSelection
    case needsFirstConversation(step: Int)
    case ready
    case recoverableError(AppError)

    var loadingTitle: String? {
        switch self {
        case .launching:
            String(localized: "正在启动")
        case .restoringSession:
            String(localized: "正在恢复身份")
        case .signingInAnonymously:
            String(localized: "正在建立连接")
        case .requestingBootstrap:
            String(localized: "正在同步")
        default:
            nil
        }
    }

    var isLoading: Bool {
        loadingTitle != nil
    }
}
