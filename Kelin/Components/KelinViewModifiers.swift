import SwiftUI

extension View {
    /// 页面径向渐变背景：中心 `#171B28` → 边缘 `#0E1118`，底色 `#10131B`。
    func kelinScreenBackground() -> some View {
        modifier(KelinScreenBackgroundModifier())
    }

    func kelinTypography(_ style: KelinTypography.Style, color: Color = KelinColor.textPrimary) -> some View {
        font(style.font)
            .foregroundStyle(color)
            .lineSpacing(style.lineSpacing)
    }

    func kelinStandardCard() -> some View {
        padding(KelinSpacing.standard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KelinColor.surfacePrimary.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.standard))
        .overlay {
            RoundedRectangle(cornerRadius: KelinRadius.standard)
                .stroke(KelinColor.borderSubtle, lineWidth: 1)
        }
    }

    /// 430 pt 及以上屏幕居中限宽，避免卡片和操作坞被无限拉宽。
    func kelinConstrainedContentWidth() -> some View {
        modifier(KelinConstrainedContentWidthModifier())
    }
}

private struct KelinConstrainedContentWidthModifier: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .frame(
                    maxWidth: min(geometry.size.width, KelinLayout.referenceCanvasWidth + 24),
                    maxHeight: .infinity
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct KelinScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                KelinColor.backgroundBase
                    .ignoresSafeArea()
                    .overlay {
                        RadialGradient(
                            colors: [
                                KelinColor.backgroundCenter,
                                KelinColor.backgroundEdge,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 420
                        )
                        .ignoresSafeArea()
                    }
            }
    }
}
