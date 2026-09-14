import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    let spiritName: String
    let isOffline: Bool
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            chatHeader

            if isOffline {
                offlineBanner
            }

            GeometryReader { geometry in
                let contentWidth = max(geometry.size.width - KelinSpacing.pageHorizontal * 2, 0)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: KelinSpacing.section) {
                            if viewModel.messages.isEmpty, !viewModel.isGenerating {
                                ChatEmptyStateView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, KelinSpacing.largeSection)
                            }

                            ForEach(viewModel.timelineItems) { item in
                                switch item {
                                case let .dayDivider(label):
                                    ChatDayDivider(label: label)
                                        .frame(maxWidth: .infinity)
                                case let .message(message):
                                    ChatMessageRow(
                                        message: message,
                                        contentWidth: contentWidth,
                                        onRetry: message.role == .user && message.status == .failed
                                            ? { retry(message) }
                                            : nil
                                    )
                                    .id(message.id)
                                }
                            }

                            if viewModel.isGenerating {
                                ChatTypingIndicatorView()
                                    .id("typing-indicator")
                            }
                        }
                        .padding(.horizontal, KelinSpacing.pageHorizontal)
                        .padding(.vertical, KelinSpacing.small)
                        .frame(maxWidth: .infinity)
                        .frame(
                            minHeight: geometry.size.height,
                            alignment: viewModel.messages.isEmpty && !viewModel.isGenerating ? .center : .bottom
                        )
                    }
                    .scrollIndicators(.hidden)
                    .allowsHitTesting(!viewModel.blocksChatChrome)
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.isGenerating) { _, isGenerating in
                        if isGenerating {
                            scrollToBottom(proxy: proxy, anchor: "typing-indicator")
                        }
                    }
                }
            }

            if viewModel.showsMicrophonePermissionPrompt {
                microphonePermissionPrompt
            } else if let voiceStatus = viewModel.voiceStatusMessage, !voiceStatus.isEmpty {
                Text(voiceStatus)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(KelinColor.accentWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .accessibilityLabel(voiceStatus)
            }

            ChatComposerBar(
                draftText: $viewModel.draftText,
                mode: viewModel.composerMode,
                canSubmit: viewModel.canSubmit,
                queueIsFull: viewModel.queueIsFull,
                voicePhase: viewModel.voicePhase,
                isVoiceQuotaBlocked: viewModel.isVoiceQuotaBlocked,
                onSend: {
                    Task {
                        try? await viewModel.submitDraft()
                    }
                },
                onSwitchToVoice: {
                    viewModel.setComposerMode(.voice)
                },
                onSwitchToText: {
                    viewModel.setComposerMode(.text)
                },
                onVoiceTouchDown: {
                    viewModel.markVoiceHoldStarted()
                },
                onVoiceBegan: {
                    Task { await viewModel.beginVoiceHold() }
                },
                onVoiceChanged: { translation, duration in
                    viewModel.updateVoiceHold(verticalTranslation: translation, duration: duration)
                },
                onVoiceEnded: { cancelled, duration in
                    Task { await viewModel.finishVoiceHold(cancelled: cancelled, duration: duration) }
                },
                onVoiceTap: {
                    viewModel.handleVoiceTap()
                },
                onCancelProcessing: {
                    viewModel.cancelVoiceProcessing()
                }
            )
            .padding(.horizontal, KelinSpacing.pageHorizontal)
            .padding(.top, KelinSpacing.small)
            .padding(.bottom, KelinSpacing.small)
            .background {
                LinearGradient(
                    colors: [
                        KelinColor.backgroundBase.opacity(0),
                        KelinColor.backgroundBase.opacity(0.95),
                        KelinColor.backgroundBase,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background {
            chatBackground
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(viewModel.blocksChatChrome)
    }

    private var chatBackground: some View {
        KelinColor.backgroundBase
            .ignoresSafeArea()
            .overlay {
                RadialGradient(
                    colors: [
                        KelinColor.backgroundCenter,
                        KelinColor.backgroundBase,
                    ],
                    center: UnitPoint(x: 0.5, y: 0.3),
                    startRadius: 0,
                    endRadius: 460
                )
                .ignoresSafeArea()
            }
    }

    private var chatHeader: some View {
        ZStack {
            HStack(spacing: 0) {
                Button(action: onBack) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .regular))
                        Text(String(localized: "房间"))
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundStyle(KelinColor.textSecondary)
                    .frame(minHeight: KelinSize.minimumTouchTarget, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.blocksChatChrome)
                .opacity(viewModel.blocksChatChrome ? 0.4 : 1)
                .accessibilityLabel(String(localized: "返回房间"))

                Spacer(minLength: 0)

                ttsButton
            }

            VStack(spacing: 2) {
                Text(spiritName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(KelinColor.textPrimary)
                    .tracking(0.4)
                if viewModel.usesStubProvider {
                    Text(String(localized: "Stub"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(KelinColor.textSecondary.opacity(0.55))
                        .accessibilityLabel(String(localized: "当前为 Stub 测试环境，不是真实模型"))
                }
            }
            .allowsHitTesting(false)
        }
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .frame(height: ChatLayout.headerHeight)
    }

    @ViewBuilder
    private var ttsButton: some View {
        if viewModel.blocksChatChrome {
            Image(systemName: "speaker.slash.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(KelinColor.textSecondary.opacity(0.4))
                .frame(width: ChatLayout.headerTTSMutedSize, height: ChatLayout.headerTTSMutedSize)
                .background(KelinColor.surfaceSecondary.opacity(0.4))
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
                .frame(width: KelinSize.minimumTouchTarget, height: KelinSize.minimumTouchTarget)
                .accessibilityLabel(String(localized: "语音播报已静音"))
        } else {
            Button {
                Task { await viewModel.toggleTTS() }
            } label: {
                Image(systemName: viewModel.isTTSPlaying ? "stop.fill" : "waveform")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(KelinColor.accent)
                    .frame(width: ChatLayout.headerSideButton, height: ChatLayout.headerSideButton)
                    .background(KelinColor.surfaceSecondary.opacity(0.8))
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }
                    .shadow(color: KelinColor.accent.opacity(0.25), radius: 6)
            }
            .buttonStyle(.plain)
            .frame(width: KelinSize.minimumTouchTarget, height: KelinSize.minimumTouchTarget)
            .accessibilityLabel(viewModel.isTTSPlaying ? String(localized: "停止播报") : String(localized: "语音播报"))
        }
    }

    private var microphonePermissionPrompt: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.compact) {
            Text(ErrorCopy.app(.permissionDenied(.microphone)).message)
                .font(.system(size: 13))
                .foregroundStyle(KelinColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: KelinSpacing.compact) {
                Button(String(localized: "暂时不用")) {
                    viewModel.dismissMicrophonePermissionPrompt()
                }
                .buttonStyle(.plain)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(KelinColor.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: KelinSize.secondaryButtonHeight)
                .background(KelinColor.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))

                Button(String(localized: "去设置")) {
                    viewModel.openSystemSettings()
                }
                .buttonStyle(.plain)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(KelinColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: KelinSize.secondaryButtonHeight)
                .background(KelinColor.accentSurface)
                .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
            }
        }
        .padding(KelinSpacing.standard)
        .background(KelinColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.standard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KelinRadius.standard, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        }
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .padding(.bottom, 4)
        .accessibilityElement(children: .contain)
    }

    private var offlineBanner: some View {
        Text(String(localized: "连不上，消息会先留在本地"))
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(KelinColor.accentWarm)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KelinSpacing.small)
            .background(KelinColor.surfaceSecondary.opacity(0.72))
    }

    private func retry(_ message: ChatMessage) {
        Task {
            try? await viewModel.retry(clientMessageID: message.clientID)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, anchor: String? = nil) {
        if let anchor {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(anchor, anchor: .bottom)
            }
            return
        }

        guard let lastID = viewModel.messages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
}

private struct ChatDayDivider: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(KelinColor.textSecondary.opacity(0.6))
            .tracking(1.2)
            .padding(.vertical, 4)
    }
}

private struct ChatMessageRow: View {
    let message: ChatMessage
    let contentWidth: CGFloat
    let onRetry: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 0)
            }

            ChatMessageBubble(
                message: message,
                maxWidth: contentWidth * (
                    message.role == .spirit
                        ? ChatLayout.spiritMaxWidthRatio
                        : ChatLayout.userMaxWidthRatio
                ),
                onRetry: onRetry
            )

            if message.role == .spirit {
                Spacer(minLength: 0)
            }
        }
    }
}
