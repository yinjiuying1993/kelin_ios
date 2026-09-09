import SwiftUI

struct OnboardingConversationView: View {
    @Bindable var appState: AppState
    let displayStep: Int

    @State private var draft = ""
    @FocusState private var isInputFocused: Bool

    private var totalSteps: Int { OnboardingConversationDefaults.totalSteps }
    private var progress: Double { Double(displayStep) / Double(totalSteps) }
    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !appState.isSendingOnboardingMessage
            && !appState.hasCompletedOnboardingConversation
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            IncubatingEggView()
                .padding(.top, KelinSpacing.standard)

            Text(String(localized: "它正在倾听你的声音"))
                .font(.system(size: 13))
                .foregroundStyle(KelinColor.textSecondary.opacity(0.8))
                .padding(.top, KelinSpacing.standard)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(appState.onboardingMessages) { message in
                            OnboardingMessageBubble(message: message)
                                .id(message.id)
                        }

                        if appState.isSendingOnboardingMessage {
                            HStack {
                                KelinLoadingDots()
                                    .padding(.horizontal, KelinSpacing.standard)
                                    .padding(.vertical, KelinSpacing.compact)
                                    .background(
                                        RoundedRectangle(cornerRadius: KelinRadius.standard)
                                            .fill(KelinColor.surfacePrimary)
                                    )
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, KelinSpacing.pageHorizontal)
                    .padding(.vertical, KelinSpacing.standard)
                }
                .onChange(of: appState.onboardingMessages.count) { _, _ in
                    scrollToLatest(using: proxy)
                }
            }

            composer
        }
        .kelinScreenBackground()
    }

    private var header: some View {
        VStack(spacing: KelinSpacing.small) {
            HStack {
                Button {
                    appState.returnToEggSelection()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24))
                        .foregroundStyle(KelinColor.textSecondary)
                        .frame(width: KelinSize.minimumTouchTarget, height: 36)
                }
                .accessibilityLabel(String(localized: "返回"))

                Spacer()

                Text("\(displayStep) / \(totalSteps)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(KelinColor.textSecondary.opacity(0.9))
                    .accessibilityLabel(String(localized: "进度 \(displayStep) / \(totalSteps)"))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 2)

                    Capsule()
                        .fill(KelinColor.accent)
                        .frame(width: geometry.size.width * progress, height: 2)
                        .shadow(color: KelinColor.accent.opacity(0.75), radius: 4)
                }
            }
            .frame(height: 2)
        }
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .padding(.top, KelinSpacing.xSmall)
    }

    private var composer: some View {
        VStack(spacing: KelinSpacing.compact) {
            HStack(spacing: 10) {
                TextField(
                    String(localized: "对它说一句话"),
                    text: $draft,
                    axis: .vertical
                )
                .lineLimit(1 ... 4)
                .font(.system(size: 15))
                .foregroundStyle(KelinColor.textPrimary)
                .padding(.horizontal, KelinSpacing.standard)
                .frame(minHeight: KelinSize.inputMinimumHeight)
                .background(
                    Capsule()
                        .fill(KelinColor.surfacePrimary)
                        .overlay {
                            Capsule()
                                .stroke(
                                    isInputFocused ? KelinColor.accent.opacity(0.6) : KelinColor.borderSubtle,
                                    lineWidth: 1
                                )
                        }
                )
                .focused($isInputFocused)
                .disabled(appState.isSendingOnboardingMessage || appState.hasCompletedOnboardingConversation)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(KelinColor.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(KelinColor.accent))
                }
                .disabled(!canSend)
                .accessibilityLabel(String(localized: "发送"))
            }
            .padding(.horizontal, KelinSpacing.pageHorizontal)

            if appState.onboardingChatError != nil {
                HStack(spacing: KelinSpacing.compact) {
                    Text(String(localized: "连不上，再试一次"))
                        .kelinTypography(KelinTypography.secondary, color: KelinColor.danger)

                    Button(String(localized: "再试一次")) {
                        appState.clearOnboardingChatError()
                        sendMessage()
                    }
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textPrimary)
                }
            }

            if appState.onboardingChatServiceUsesStub {
                Text(String(localized: "对话由测试 Stub 生成"))
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary.opacity(0.7))
            }

            if appState.onboardingCompleteError != nil {
                HStack(spacing: KelinSpacing.compact) {
                    Text(String(localized: "孵化未完成，再试一次"))
                        .kelinTypography(KelinTypography.secondary, color: KelinColor.danger)

                    Button(String(localized: "再试一次")) {
                        appState.clearOnboardingCompleteError()
                        appState.retryOnboardingComplete()
                    }
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textPrimary)
                }
            }
        }
        .padding(.bottom, KelinSpacing.standard)
    }

    private func sendMessage() {
        let content = draft
        draft = ""
        Task {
            await appState.sendOnboardingMessage(content: content)
        }
    }

    private func scrollToLatest(using proxy: ScrollViewProxy) {
        guard let lastID = appState.onboardingMessages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
}

#Preview("S04 初识对话") {
    OnboardingConversationPreviewHost()
}

@MainActor
private struct OnboardingConversationPreviewHost: View {
    @State private var appState = AppState(
        auth: MockAuthService(),
        localStore: LocalStore(modelContainer: try! KelinModelContainerFactory.makeInMemoryContainer()),
        bootstrapService: MockBootstrapService(mode: .newUser),
        hatchService: MockHatchService()
    )

    var body: some View {
        Group {
            if case let .needsFirstConversation(step) = appState.phase {
                OnboardingConversationView(appState: appState, displayStep: step)
            } else {
                ProgressView()
            }
        }
        .task {
            await bootstrapToConversation()
        }
    }

    private func bootstrapToConversation() async {
        appState.beginLaunch()
        while appState.phase != .needsAgreement {
            try? await Task.sleep(for: .milliseconds(10))
        }
        await appState.submitAgreement(
            aiDisclosureAccepted: true,
            hasViewedUserTerms: true,
            hasViewedDataNotice: true
        )
        await appState.createSpirit(selectedOption: .variable)
    }
}
