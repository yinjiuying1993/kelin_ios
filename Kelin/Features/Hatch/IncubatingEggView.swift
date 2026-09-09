import SwiftUI

struct IncubatingEggView: View {
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(KelinColor.accent.opacity(0.1))
                .frame(width: 256, height: 256)
                .blur(radius: 24)

            ZStack {
                EggShellShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.13, green: 0.16, blue: 0.23).opacity(0.9),
                                Color(red: 0.08, green: 0.09, blue: 0.15).opacity(0.95),
                                Color(red: 0.04, green: 0.05, blue: 0.09),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        EggShellShape()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.7), radius: 22, y: 20)
                    .overlay {
                        Ellipse()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        KelinColor.accent.opacity(0.45),
                                        KelinColor.accentPressed.opacity(0.2),
                                        .clear,
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 96, height: 112)
                            .blur(radius: 8)
                            .offset(y: 24)
                    }
                    .overlay(alignment: .topLeading) {
                        Ellipse()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 48)
                            .rotationEffect(.degrees(-22))
                            .offset(x: 16, y: 8)
                    }
                    .overlay {
                        VioletCrackShape()
                            .stroke(Color.white.opacity(0.95), lineWidth: 1)
                            .shadow(color: KelinColor.accent.opacity(0.85), radius: 4)
                    }
                    .frame(width: 160, height: 200)

                Ellipse()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 112, height: 20)
                    .blur(radius: 8)
                    .offset(y: 108)
            }
            .offset(y: floatOffset)
        }
        .frame(height: 240)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                floatOffset = -3.5
            }
        }
    }
}

private struct VioletCrackShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.34))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX + 5, y: rect.height * 0.51),
            control: CGPoint(x: rect.midX + 10, y: rect.height * 0.43)
        )
        path.addLine(to: CGPoint(x: rect.midX + 2, y: rect.height * 0.59))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX + 10, y: rect.height * 0.71),
            control: CGPoint(x: rect.midX - 2, y: rect.height * 0.65)
        )
        path.move(to: CGPoint(x: rect.midX + 2, y: rect.height * 0.51))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX - 9, y: rect.height * 0.57),
            control: CGPoint(x: rect.midX - 6, y: rect.height * 0.545)
        )
        return path
    }
}
