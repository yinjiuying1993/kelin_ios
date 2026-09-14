import SwiftUI

struct AgreementView: View {
    @Bindable var appState: AppState

    @State private var isAIDisclosureAccepted = false
    @State private var presentedDocument: ConsentDocumentKind?

    private var canSubmit: Bool {
        isAIDisclosureAccepted && !appState.isSubmittingAgreement
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: KelinSpacing.largeSection)

            DormantCoreMark()
                .padding(.bottom, KelinSpacing.section)

            Text(String(localized: "刻灵"))
                .kelinTypography(KelinTypography.largeTitle)
                .tracking(4)
                .accessibilityAddTraits(.isHeader)

            Text(String(localized: "相处，会在身上留下痕迹"))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                .padding(.top, KelinSpacing.small)

            Spacer()

            VStack(spacing: 0) {
                Button {
                    Task {
                        await appState.submitAgreement(
                            aiDisclosureAccepted: isAIDisclosureAccepted,
                            hasViewedUserTerms: true,
                            hasViewedDataNotice: true
                        )
                    }
                } label: {
                    Text(String(localized: "开始孵化"))
                }
                .buttonStyle(
                    AgreementPrimaryButtonStyle(
                        isEnabled: canSubmit,
                        isLoading: appState.isSubmittingAgreement
                    )
                )
                .disabled(!canSubmit)
                .accessibilityHint(submitAccessibilityHint)

                aiDisclosureRow
                    .padding(.top, KelinSpacing.standard)

                documentLinks
                    .padding(.top, KelinSpacing.largeSection)

                if appState.agreementError != nil {
                    failureBanner
                        .padding(.top, KelinSpacing.standard)
                }
            }
            .frame(maxWidth: KelinLayout.standardContentWidth)
            .padding(.horizontal, KelinSpacing.pageHorizontal)
            .padding(.bottom, KelinSpacing.standard)
        }
        .kelinScreenBackground()
        .sheet(item: $presentedDocument) { kind in
            ConsentDocumentSheet(kind: kind) {
                presentedDocument = nil
            }
        }
    }

    private var submitAccessibilityHint: String {
        if !isAIDisclosureAccepted {
            return String(localized: "需要先确认人工智能声明")
        }
        return String(localized: "进入选蛋")
    }

    private var aiDisclosureRow: some View {
        Button {
            isAIDisclosureAccepted.toggle()
            appState.clearAgreementError()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isAIDisclosureAccepted
                                ? KelinColor.accent
                                : KelinColor.surfaceSecondary
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isAIDisclosureAccepted
                                        ? KelinColor.accent
                                        : KelinColor.borderSubtle,
                                    lineWidth: 1
                                )
                        }
                        .frame(width: 20, height: 20)

                    if isAIDisclosureAccepted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(KelinColor.textPrimary)
                    }
                }

                Text(String(localized: "我知道它是人工智能"))
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(minHeight: KelinSize.minimumTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "我知道它是人工智能"))
        .accessibilityAddTraits(isAIDisclosureAccepted ? .isSelected : [])
    }

    private var documentLinks: some View {
        HStack(spacing: KelinSpacing.compact) {
            Button(String(localized: "用户说明")) {
                presentedDocument = .userTerms
            }
            .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary.opacity(0.7))

            Text("·")
                .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary.opacity(0.3))

            Button(String(localized: "数据说明")) {
                presentedDocument = .dataNotice
            }
            .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary.opacity(0.7))
        }
    }

    private var failureBanner: some View {
        HStack(spacing: KelinSpacing.compact) {
            Text(String(localized: "连不上，再试一次"))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.danger)

            Button(String(localized: "再试一次")) {
                appState.clearAgreementError()
                Task {
                    await appState.submitAgreement(
                        aiDisclosureAccepted: isAIDisclosureAccepted,
                        hasViewedUserTerms: true,
                        hasViewedDataNotice: true
                    )
                }
            }
            .kelinTypography(KelinTypography.secondary, color: KelinColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AgreementPrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KelinTypography.body.font.weight(.semibold))
            .foregroundStyle(isEnabled ? KelinColor.textPrimary : KelinColor.textSecondary.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: KelinSize.primaryButtonHeight)
            .background(
                isEnabled
                    ? (configuration.isPressed ? KelinColor.accentPressed : KelinColor.accent)
                    : KelinColor.surfaceSecondary
            )
            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small))
            .overlay {
                if !isEnabled {
                    RoundedRectangle(cornerRadius: KelinRadius.small)
                        .stroke(KelinColor.borderSubtle, lineWidth: 1)
                }
            }
            .shadow(
                color: isEnabled ? KelinColor.accent.opacity(0.25) : .clear,
                radius: 12,
                y: 4
            )
            .overlay {
                if isLoading {
                    KelinLoadingDots()
                }
            }
            .opacity(isLoading ? 0.92 : 1)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.99 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview("S02 启动协议") {
    AgreementPreviewHost()
}

@MainActor
private struct AgreementPreviewHost: View {
    @State private var appState = AppState(
        auth: MockAuthService(),
        localStore: LocalStore(modelContainer: try! KelinModelContainerFactory.makeInMemoryContainer()),
        bootstrapService: MockBootstrapService(mode: .newUser)
    )

    var body: some View {
        AgreementView(appState: appState)
            .task {
                appState.beginLaunch()
                while appState.phase != .needsAgreement {
                    try? await Task.sleep(for: .milliseconds(10))
                    if Task.isCancelled { return }
                }
            }
    }
}
