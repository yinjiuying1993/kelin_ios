import SwiftUI

enum KelinColor {
    static let backgroundBase = Color(hex: 0x10131B)
    static let backgroundCenter = Color(hex: 0x171B28)
    static let backgroundEdge = Color(hex: 0x0E1118)
    static let surfacePrimary = Color(hex: 0x181D2A)
    static let surfaceSecondary = Color(hex: 0x202638)
    static let textPrimary = Color(hex: 0xF2F4F8)
    static let textSecondary = Color(hex: 0x9BA5B8)
    static let accent = Color(hex: 0x8C7CFF)
    static let accentPressed = Color(hex: 0x7465E8)
    static let accentSurface = Color(hex: 0x2B2750)
    static let accentWarm = Color(hex: 0xF2B86B)
    static let accentCold = Color(hex: 0x73B8D4)
    static let success = Color(hex: 0x7BC8A4)
    static let danger = Color(hex: 0xDB6B78)
    static let borderSubtle = Color.white.opacity(0.08)
}

enum KelinSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let compact: CGFloat = 12
    static let standard: CGFloat = 16
    static let pageHorizontal: CGFloat = 20
    static let section: CGFloat = 24
    static let largeSection: CGFloat = 32
}

enum KelinRadius {
    static let small: CGFloat = 14
    static let standard: CGFloat = 18
    static let large: CGFloat = 24
}

enum KelinSize {
    static let minimumTouchTarget: CGFloat = 44
    static let primaryButtonHeight: CGFloat = 52
    static let secondaryButtonHeight: CGFloat = 44
    static let inputMinimumHeight: CGFloat = 48
    static let settingsRowHeight: CGFloat = 52
    static let roomActionDockHeight: CGFloat = 72
}

enum KelinTypography {
    struct Style {
        let font: Font
        let size: CGFloat
        let lineHeight: CGFloat

        var lineSpacing: CGFloat {
            lineHeight - size
        }
    }

    static let largeTitle = Style(
        font: .system(size: 28, weight: .semibold),
        size: 28,
        lineHeight: 34
    )
    static let pageTitle = Style(
        font: .system(size: 20, weight: .semibold),
        size: 20,
        lineHeight: 25
    )
    static let cardTitle = Style(
        font: .system(size: 17, weight: .semibold),
        size: 17,
        lineHeight: 22
    )
    static let body = Style(
        font: .system(size: 15),
        size: 15,
        lineHeight: 21
    )
    static let secondary = Style(
        font: .system(size: 13),
        size: 13,
        lineHeight: 18
    )
    static let label = Style(
        font: .system(size: 12, weight: .medium),
        size: 12,
        lineHeight: 16
    )
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
