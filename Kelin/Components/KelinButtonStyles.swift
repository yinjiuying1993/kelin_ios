import SwiftUI

struct KelinPrimaryButtonStyle: ButtonStyle {
    var isLoading = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KelinTypography.body.font.weight(.semibold))
            .foregroundStyle(KelinColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: KelinSize.primaryButtonHeight)
            .background(
                configuration.isPressed
                    ? KelinColor.accentPressed
                    : KelinColor.accent
            )
            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small))
            .overlay {
                if isLoading {
                    KelinLoadingDots()
                }
            }
            .opacity(isLoading ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct KelinSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KelinTypography.body.font)
            .foregroundStyle(KelinColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: KelinSize.secondaryButtonHeight)
            .background(
                configuration.isPressed
                    ? KelinColor.surfaceSecondary.opacity(0.85)
                    : Color.clear
            )
            .overlay {
                RoundedRectangle(cornerRadius: KelinRadius.small)
                    .stroke(KelinColor.borderSubtle, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == KelinPrimaryButtonStyle {
    static var kelinPrimary: KelinPrimaryButtonStyle { KelinPrimaryButtonStyle() }

    static func kelinPrimary(isLoading: Bool) -> KelinPrimaryButtonStyle {
        KelinPrimaryButtonStyle(isLoading: isLoading)
    }
}

extension ButtonStyle where Self == KelinSecondaryButtonStyle {
    static var kelinSecondary: KelinSecondaryButtonStyle { KelinSecondaryButtonStyle() }
}
