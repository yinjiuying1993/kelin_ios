import SwiftUI

struct ChatVoiceRecordingHUD: View {
    let duration: TimeInterval
    let willCancel: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hintLifted = false

    var body: some View {
        VStack(spacing: 14) {
            hint

            HStack(spacing: KelinSpacing.standard) {
                ChatVoiceWaveformView(willCancel: willCancel, reduceMotion: reduceMotion)

                HStack(spacing: 8) {
                    Circle()
                        .fill(KelinColor.accent.opacity(willCancel ? 0.35 : 0.9))
                        .frame(width: 8, height: 8)
                        .shadow(color: willCancel ? .clear : KelinColor.accent.opacity(0.7), radius: 3)

                    Text(VoiceRules.formattedHoldDuration(duration))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(KelinColor.textPrimary)
                        .tracking(0.6)
                        .accessibilityLabel(VoiceRules.formattedHoldDuration(duration))
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: ChatLayout.waveformHUDMaxWidth)
            .frame(height: ChatLayout.waveformHUDHeight)
            .background(KelinColor.surfacePrimary.opacity(0.8))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.standard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: KelinRadius.standard, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
            .opacity(willCancel ? 0.55 : 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(VoiceComposerPresentation.hintLabel(willCancel: willCancel))
    }

    private var hint: some View {
        HStack(spacing: 4) {
            Image(systemName: "chevron.up.2")
                .font(.system(size: 15, weight: .medium))
            Text(VoiceComposerPresentation.hintLabel(willCancel: willCancel))
                .font(.system(size: 13, weight: .medium))
                .tracking(-0.2)
        }
        .foregroundStyle(willCancel ? KelinColor.danger : KelinColor.textSecondary)
        .offset(y: reduceMotion || willCancel || !hintLifted ? 0 : -4)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                hintLifted = true
            }
        }
    }
}

struct ChatVoiceWaveformView: View {
    let willCancel: Bool
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.14, paused: reduceMotion)) { timeline in
            HStack(alignment: .center, spacing: ChatLayout.waveformBarSpacing) {
                ForEach(0..<ChatLayout.waveformBarCount, id: \.self) { index in
                    Capsule()
                        .fill(KelinColor.accent.opacity(barOpacity(index)))
                        .frame(width: ChatLayout.waveformBarWidth, height: barHeight(index, at: timeline.date))
                }
            }
            .frame(height: 24)
        }
    }

    private func barOpacity(_ index: Int) -> Double {
        let base = index == 2 || index == 4 || index == 6 ? 1.0 : 0.55 + Double(index % 3) * 0.1
        return willCancel ? base * 0.45 : base
    }

    private func barHeight(_ index: Int, at date: Date) -> CGFloat {
        if reduceMotion {
            let rest: [CGFloat] = [8, 12, 16, 11, 18, 13, 16, 10, 8]
            return rest[index]
        }

        let phase = date.timeIntervalSinceReferenceDate * 8 + Double(index) * 0.7
        return 6 + CGFloat((sin(phase) + 1) / 2) * 16
    }
}
