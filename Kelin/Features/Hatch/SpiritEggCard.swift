import SwiftUI

struct EggShellShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect)
        return path
    }
}

struct SpiritEggCard: View {
    let option: EggSelectionOption
    let isSelected: Bool

    private var accent: Color {
        Color(
            red: Double((option.accentColor >> 16) & 0xFF) / 255,
            green: Double((option.accentColor >> 8) & 0xFF) / 255,
            blue: Double(option.accentColor & 0xFF) / 255
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                EggShellShape()
                    .fill(KelinColor.surfaceSecondary.opacity(isSelected ? 0.9 : 0.85))
                    .overlay {
                        EggShellShape()
                            .stroke(Color.white.opacity(isSelected ? 0.1 : 0.06), lineWidth: 1)
                    }
                    .overlay {
                        EggShellShape()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        .clear,
                                        KelinColor.backgroundEdge.opacity(0.85),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .overlay(alignment: .topLeading) {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 36, height: 36)
                            .blur(radius: 3)
                            .offset(x: -8, y: -12)
                    }
                    .overlay(alignment: .bottom) {
                        ZStack {
                            Ellipse()
                                .fill(accent.opacity(0.25))
                                .frame(width: 36, height: 44)
                                .blur(radius: 8)
                                .offset(y: 4)

                            Ellipse()
                                .fill(accent.opacity(option == .variable ? 0.9 : 0.8))
                                .frame(width: 14, height: 20)
                                .blur(radius: option == .variable ? 1 : 2)
                                .offset(y: 6)
                        }
                    }
                    .frame(width: 76, height: 102)
            }
            .padding(.top, KelinSpacing.standard)

            VStack(spacing: KelinSpacing.xSmall) {
                Text(option.title)
                    .kelinTypography(
                        KelinTypography.cardTitle,
                        color: isSelected ? accent : KelinColor.textPrimary
                    )

                Text(option.subtitle)
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
            }
            .padding(.top, KelinSpacing.compact)
            .padding(.bottom, KelinSpacing.compact)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 238)
        .background(
            RoundedRectangle(cornerRadius: KelinRadius.standard)
                .fill(isSelected ? KelinColor.accentSurface : KelinColor.surfacePrimary.opacity(0.95))
        )
        .overlay {
            RoundedRectangle(cornerRadius: KelinRadius.standard)
                .stroke(
                    isSelected ? KelinColor.accent : KelinColor.borderSubtle,
                    lineWidth: 1
                )
        }
        .shadow(
            color: isSelected ? KelinColor.accent.opacity(0.25) : .clear,
            radius: 10
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(option.title)，\(option.subtitle)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
