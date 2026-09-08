import SwiftUI

struct LaunchGateView: View {
    let phase: AppPhase
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            if let loadingTitle = phase.loadingTitle {
                KelinStatusCard(state: .loading(title: loadingTitle))
                    .padding(KelinSpacing.pageHorizontal)
            } else if case let .recoverableError(error) = phase {
                KelinStatusCard(
                    state: .failure(ErrorCopy.app(error)),
                    recoveryAction: onRetry
                )
                .padding(KelinSpacing.pageHorizontal)
            }
        }
        .kelinScreenBackground()
    }
}

#Preview("恢复身份") {
    LaunchGateView(phase: .restoringSession, onRetry: {})
}

#Preview("可恢复错误") {
    LaunchGateView(
        phase: .recoverableError(.networkUnavailable),
        onRetry: {}
    )
}
