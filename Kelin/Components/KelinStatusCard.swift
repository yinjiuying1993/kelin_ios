import SwiftUI

struct KelinStatusCard: View {
    enum State {
        case loading(title: String)
        case failure(ErrorCopy)
    }

    let state: State
    var recoveryAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.compact) {
            switch state {
            case let .loading(title):
                loadingContent(title: title)
            case let .failure(copy):
                failureContent(copy: copy)
            }
        }
        .kelinStandardCard()
    }

    private func loadingContent(title: String) -> some View {
        HStack(spacing: KelinSpacing.compact) {
            KelinLoadingDots()

            Text(title)
                .kelinTypography(KelinTypography.body)
        }
        .frame(minHeight: KelinSize.minimumTouchTarget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private func failureContent(copy: ErrorCopy) -> some View {
        Label {
            Text(copy.title)
                .kelinTypography(KelinTypography.cardTitle)
        } icon: {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: KelinIconSize.standard))
                .foregroundStyle(KelinColor.danger)
        }
        .foregroundStyle(KelinColor.textPrimary)

        Text(copy.message)
            .kelinTypography(KelinTypography.body, color: KelinColor.textSecondary)

        if
            let recoveryActionTitle = copy.recoveryActionTitle,
            let recoveryAction
        {
            Button(recoveryActionTitle, action: recoveryAction)
                .buttonStyle(.kelinPrimary)
        }
    }
}

#Preview("加载") {
    ZStack {
        KelinColor.backgroundBase.ignoresSafeArea()
        KelinStatusCard(state: .loading(title: "正在准备基础数据"))
            .padding(KelinSpacing.pageHorizontal)
    }
}

#Preview("配置错误") {
    ZStack {
        KelinColor.backgroundBase.ignoresSafeArea()
        KelinStatusCard(
            state: .failure(
                ErrorCopy.configuration(
                    .missingValue(key: AppConfig.Key.apiBaseURL)
                )
            )
        )
        .padding(KelinSpacing.pageHorizontal)
    }
}
