import SwiftUI

/// S02 顶部 dormant core 视觉：环境光晕 + 慢速虚线环 + 中心光点。
struct DormantCoreMark: View {
    @State private var ringRotation: Angle = .zero

    var body: some View {
        ZStack {
            Circle()
                .fill(KelinColor.accentSurface.opacity(0.3))
                .frame(width: 288, height: 288)
                .blur(radius: 40)

            Circle()
                .fill(KelinColor.accent.opacity(0.1))
                .frame(width: 192, height: 192)
                .blur(radius: 25)

            Circle()
                .fill(KelinColor.accent.opacity(0.2))
                .frame(width: 144, height: 144)
                .blur(radius: 16)

            Circle()
                .stroke(
                    KelinColor.accent.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1, dash: [2, 12])
                )
                .frame(width: 96, height: 96)
                .rotationEffect(ringRotation)

            Circle()
                .fill(KelinColor.textPrimary.opacity(0.92))
                .frame(width: 12, height: 12)
                .shadow(color: KelinColor.accent.opacity(0.85), radius: 12)
        }
        .frame(width: 96, height: 96)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) {
                ringRotation = .degrees(360)
            }
        }
    }
}
