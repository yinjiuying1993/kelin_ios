import SwiftUI

struct ChatTypingIndicatorView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 0.35)) { timeline in
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(KelinColor.primaryTint)
                                .frame(width: 8, height: 8)
                                .opacity(opacity(for: index, date: timeline.date))
                        }
                    }
                }
            }
            .padding(.horizontal, KelinSpacing.standard)
            .padding(.vertical, KelinSpacing.compact)
            .background(KelinColor.surfacePrimary)
            .clipShape(bubbleShape)
            .overlay {
                bubbleShape.stroke(Color.white.opacity(0.05), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
            .accessibilityLabel(String(localized: "精灵正在输入"))

            Spacer(minLength: 0)
        }
    }

    private var bubbleShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: KelinRadius.small,
            bottomLeadingRadius: KelinRadius.standard,
            bottomTrailingRadius: KelinRadius.standard,
            topTrailingRadius: KelinRadius.standard
        )
    }

    private func opacity(for index: Int, date: Date) -> Double {
        guard !reduceMotion else {
            return index == 1 ? 1 : 0.45
        }

        let phase = date.timeIntervalSinceReferenceDate
        let stagger = Double(index) * 0.2
        let wave = sin((phase + stagger) * (.pi * 2 / 1.4))
        return 0.35 + (wave + 1) * 0.325
    }
}
