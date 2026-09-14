import SwiftUI

struct ChatComposerBar: View {
    @Binding var draftText: String
    let mode: ChatComposerMode
    let canSubmit: Bool
    let queueIsFull: Bool
    let voicePhase: VoiceComposerPhase
    let isVoiceQuotaBlocked: Bool
    let onSend: () -> Void
    let onSwitchToVoice: () -> Void
    let onSwitchToText: () -> Void
    let onVoiceTouchDown: () -> Void
    let onVoiceBegan: () -> Void
    let onVoiceChanged: (CGFloat, TimeInterval) -> Void
    let onVoiceEnded: (Bool, TimeInterval) -> Void
    let onVoiceTap: () -> Void
    let onCancelProcessing: () -> Void

    @State private var holdStartedAt: Date?
    @State private var isHolding = false

    private var trimmedDraft: String {
        draftText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sendEnabled: Bool {
        !trimmedDraft.isEmpty && canSubmit
    }

    private var isRecording: Bool {
        voicePhase.isRecording || isHolding
    }

    private var isProcessing: Bool {
        voicePhase.isProcessing
    }

    private var willCancel: Bool {
        voicePhase.willCancel
    }

    var body: some View {
        VStack(spacing: 6) {
            if queueIsFull {
                Text(String(localized: "排队已满，请稍候"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(KelinColor.accentWarm)
            }

            if mode == .voice, isRecording {
                ChatVoiceRecordingHUD(
                    duration: voicePhase.recordingDuration,
                    willCancel: willCancel
                )
            }

            if mode == .text {
                textComposer
            } else {
                voiceComposer
            }
        }
    }

    private var textComposer: some View {
        HStack(spacing: 8) {
            Button(action: onSwitchToVoice) {
                Image(systemName: "mic")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(KelinColor.textSecondary)
                    .frame(width: ChatLayout.composerControl, height: ChatLayout.composerControl)
                    .background(KelinColor.surfaceSecondary)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isVoiceQuotaBlocked)
            .opacity(isVoiceQuotaBlocked ? 0.4 : 1)
            .accessibilityLabel(String(localized: "切换到语音输入"))

            TextField(
                "",
                text: $draftText,
                prompt: Text(String(localized: "说点什么..."))
                    .foregroundStyle(KelinColor.textSecondary.opacity(0.5)),
                axis: .vertical
            )
            .lineLimit(1...4)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(size: 15))
            .foregroundStyle(KelinColor.textPrimary)
            .padding(.horizontal, KelinSpacing.standard)
            .frame(minHeight: ChatLayout.composerInnerHeight)
            .background(KelinColor.surfacePrimary)
            .clipShape(Capsule())
            .accessibilityLabel(String(localized: "说点什么"))

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(sendEnabled ? KelinColor.onPrimary : KelinColor.onPrimary.opacity(0.45))
                    .frame(width: ChatLayout.composerControl, height: ChatLayout.composerControl)
                    .background(sendEnabled ? KelinColor.accent : KelinColor.accent.opacity(0.45))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!sendEnabled)
            .accessibilityLabel(String(localized: "发送"))
        }
        .padding(ChatLayout.composerChromePadding)
        .background(KelinColor.backgroundBase.opacity(0.9))
        .background(.ultraThinMaterial)
        .overlay {
            Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.6), radius: 16, y: 8)
    }

    private var voiceComposer: some View {
        HStack(spacing: 10) {
            Button(action: onSwitchToText) {
                Image(systemName: "keyboard")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(KelinColor.textSecondary)
                    .frame(width: ChatLayout.voiceModeButtonWidth, height: ChatLayout.voiceHoldHeight)
                    .background(KelinColor.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: ChatLayout.voiceModeButtonCornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: ChatLayout.voiceModeButtonCornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .disabled(isRecording)
            .opacity(isRecording ? 0.4 : 1)
            .accessibilityLabel(String(localized: "切换至键盘输入"))

            if isProcessing {
                processingHotspot
            } else {
                holdHotspot
            }
        }
    }

    private var holdHotspot: some View {
        let label = VoiceComposerPresentation.holdLabel(isRecording: isRecording, willCancel: willCancel)
        return HStack(spacing: 8) {
            if isRecording {
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .medium))
            }
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .tracking(0.4)
        }
        .foregroundStyle(willCancel ? KelinColor.danger : KelinColor.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: ChatLayout.voiceHoldHeight)
        .background(isRecording ? KelinColor.accentSurface : KelinColor.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: ChatLayout.voiceHoldCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ChatLayout.voiceHoldCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(isRecording ? 0.1 : 0.04), lineWidth: 1)
        }
        .shadow(color: isRecording && !willCancel ? KelinColor.accent.opacity(0.25) : .clear, radius: 10)
        .contentShape(RoundedRectangle(cornerRadius: ChatLayout.voiceHoldCornerRadius, style: .continuous))
        .gesture(holdGesture)
        .accessibilityLabel(label)
        .accessibilityHint(
            willCancel
                ? String(localized: "松手取消")
                : String(localized: "上滑取消，松开发送")
        )
    }

    private var processingHotspot: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(KelinColor.accent)
            Text(VoiceComposerPresentation.processingLabel(voicePhase) ?? "")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(KelinColor.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button(action: onCancelProcessing) {
                Text(String(localized: "取消"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(KelinColor.textSecondary)
                    .padding(.horizontal, 10)
                    .frame(minHeight: KelinSize.minimumTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "取消"))
        }
        .padding(.horizontal, KelinSpacing.standard)
        .frame(maxWidth: .infinity)
        .frame(height: ChatLayout.voiceHoldHeight)
        .background(KelinColor.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: ChatLayout.voiceHoldCornerRadius, style: .continuous))
    }

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isHolding {
                    isHolding = true
                    holdStartedAt = Date()
                    onVoiceTouchDown()
                    onVoiceBegan()
                }
                let duration = Date().timeIntervalSince(holdStartedAt ?? Date())
                onVoiceChanged(value.translation.height, duration)
            }
            .onEnded { value in
                let duration = Date().timeIntervalSince(holdStartedAt ?? Date())
                let cancelled = VoiceRules.willCancel(verticalTranslation: value.translation.height)
                isHolding = false
                holdStartedAt = nil
                if VoiceRules.isTap(duration: duration), !cancelled {
                    onVoiceTap()
                    return
                }
                onVoiceEnded(cancelled, duration)
            }
    }
}
