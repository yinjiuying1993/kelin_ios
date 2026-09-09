import SwiftUI

struct EggSelectionView: View {
    @Bindable var appState: AppState

    @State private var selectedOption: EggSelectionOption = .variable

    private var accent: Color {
        Color(
            red: Double((selectedOption.accentColor >> 16) & 0xFF) / 255,
            green: Double((selectedOption.accentColor >> 8) & 0xFF) / 255,
            blue: Double(selectedOption.accentColor & 0xFF) / 255
        )
    }

    private var canSubmit: Bool {
        !appState.isSubmittingHatch
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            VStack(alignment: .leading, spacing: 0) {
                Text(String(localized: "这枚蛋还没有性格"))
                    .kelinTypography(KelinTypography.largeTitle)
                    .accessibilityAddTraits(.isHeader)

                Text(String(localized: "温度只决定它最初靠近你的方式"))
                    .font(.system(size: 14))
                    .foregroundStyle(KelinColor.textSecondary)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, KelinSpacing.pageHorizontal)
            .padding(.top, KelinSpacing.small)

            ZStack {
                Circle()
                    .fill(accent.opacity(selectedOption.glowOpacity))
                    .frame(width: 240, height: 240)
                    .blur(radius: 32)
                    .animation(.easeOut(duration: 0.7), value: selectedOption)

                VStack(spacing: KelinSpacing.largeSection) {
                    HStack(spacing: KelinSpacing.compact) {
                        ForEach(EggSelectionOption.allCases) { option in
                            Button {
                                selectedOption = option
                                appState.clearHatchError()
                            } label: {
                                SpiritEggCard(
                                    option: option,
                                    isSelected: selectedOption == option
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(String(localized: "选择蛋温"))
                        }
                    }
                    .frame(maxWidth: KelinLayout.standardContentWidth)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(String(localized: "选择蛋温"))

                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 15))
                            .foregroundStyle(KelinColor.textSecondary)

                        Text(selectedOption.hint)
                            .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .animation(.easeOut(duration: 0.2), value: selectedOption)
                    }
                    .frame(minHeight: 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: KelinSpacing.compact) {
                Button {
                    Task {
                        await appState.createSpirit(selectedOption: selectedOption)
                    }
                } label: {
                    Text(String(localized: "碰一碰它"))
                }
                .buttonStyle(.kelinPrimary(isLoading: appState.isSubmittingHatch))
                .disabled(!canSubmit)
                .frame(maxWidth: KelinLayout.standardContentWidth)

                Text(String(localized: "以后不能重新选择蛋温"))
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)

                if appState.hatchError != nil {
                    hatchFailureBanner
                }
            }
            .padding(.horizontal, KelinSpacing.pageHorizontal)
            .padding(.bottom, KelinSpacing.standard)
        }
        .kelinScreenBackground()
    }

    private var navigationBar: some View {
        HStack {
            Button {
                appState.returnToAgreement()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(KelinColor.textPrimary)
                    .frame(width: KelinSize.minimumTouchTarget, height: KelinSize.minimumTouchTarget)
            }
            .accessibilityLabel(String(localized: "返回"))

            Spacer()
        }
        .padding(.horizontal, KelinSpacing.standard)
    }

    private var hatchFailureBanner: some View {
        HStack(spacing: KelinSpacing.compact) {
            Text(String(localized: "连不上，再试一次"))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.danger)

            Button(String(localized: "再试一次")) {
                appState.clearHatchError()
                Task {
                    await appState.createSpirit(selectedOption: selectedOption)
                }
            }
            .kelinTypography(KelinTypography.secondary, color: KelinColor.textPrimary)
        }
        .padding(.top, KelinSpacing.small)
    }
}

#Preview("S03 选蛋") {
    EggSelectionPreviewHost()
}

@MainActor
private struct EggSelectionPreviewHost: View {
    @State private var appState = AppState(
        auth: MockAuthService(),
        localStore: LocalStore(modelContainer: try! KelinModelContainerFactory.makeInMemoryContainer()),
        bootstrapService: MockBootstrapService(mode: .newUser),
        hatchService: MockHatchService()
    )

    var body: some View {
        EggSelectionView(appState: appState)
            .task {
                appState.beginLaunch()
                while appState.phase != .needsAgreement {
                    try? await Task.sleep(for: .milliseconds(10))
                    if Task.isCancelled { return }
                }
                await appState.submitAgreement(
                    aiDisclosureAccepted: true,
                    hasViewedUserTerms: true,
                    hasViewedDataNotice: true
                )
            }
    }
}
