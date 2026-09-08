import SwiftUI

/// 三枚缓慢明暗变化的光点，用于 AI 生成与页面加载态。
struct KelinLoadingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 0.4)) { timeline in
            HStack(spacing: KelinSpacing.small) {
                ForEach(0 ..< 3, id: \.self) { index in
                    Circle()
                        .fill(KelinColor.accent)
                        .frame(width: 6, height: 6)
                        .opacity(opacity(for: index, date: timeline.date))
                }
            }
        }
        .accessibilityLabel(String(localized: "正在加载"))
    }

    private func opacity(for index: Int, date: Date) -> Double {
        guard !reduceMotion else {
            return index == 1 ? 1 : 0.45
        }

        let phase = date.timeIntervalSinceReferenceDate
        let stagger = Double(index) * 0.35
        let wave = sin((phase + stagger) * 2.4)
        return 0.35 + (wave + 1) * 0.325
    }
}

#Preview {
    ZStack {
        KelinColor.backgroundBase.ignoresSafeArea()
        KelinLoadingDots()
    }
}
