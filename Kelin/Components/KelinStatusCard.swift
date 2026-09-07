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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KelinSpacing.standard)
        .background(KelinColor.surfacePrimary.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.standard))
        .overlay {
            RoundedRectangle(cornerRadius: KelinRadius.standard)
                .stroke(KelinColor.borderSubtle, lineWidth: 1)
        }
    }

    private func loadingContent(title: String) -> some View {
        HStack(spacing: KelinSpacing.compact) {
            ProgressView()
                .tint(KelinColor.accent)

            Text(title)
                .font(KelinTypography.body.font)
                .foregroundStyle(KelinColor.textPrimary)
                .lineSpacing(KelinTypography.body.lineSpacing)
        }
        .frame(minHeight: KelinSize.minimumTouchTarget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private func failureContent(copy: ErrorCopy) -> some View {
        Label {
            Text(copy.title)
                .font(KelinTypography.cardTitle.font)
                .lineSpacing(KelinTypography.cardTitle.lineSpacing)
        } icon: {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(KelinColor.danger)
        }
        .foregroundStyle(KelinColor.textPrimary)

        Text(copy.message)
            .font(KelinTypography.body.font)
            .foregroundStyle(KelinColor.textSecondary)
            .lineSpacing(KelinTypography.body.lineSpacing)

        if
            let recoveryActionTitle = copy.recoveryActionTitle,
            let recoveryAction
        {
            Button(recoveryActionTitle, action: recoveryAction)
                .font(KelinTypography.body.font.weight(.semibold))
                .foregroundStyle(KelinColor.textPrimary)
                .frame(minHeight: KelinSize.minimumTouchTarget)
                .padding(.horizontal, KelinSpacing.standard)
                .background(KelinColor.accent)
                .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small))
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
