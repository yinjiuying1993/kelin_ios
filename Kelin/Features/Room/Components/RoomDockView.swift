import SwiftUI

struct RoomDockView: View {
    let primaryAction: RoomDockAction
    let onPrimary: () -> Void
    let onFeed: () -> Void
    let onFootprints: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            dockButton(
                title: leadingTitle,
                systemImage: leadingSymbol,
                filled: true,
                isPrimary: isLeadingPrimary,
                action: leadingAction
            )
            dockDivider
            dockButton(
                title: String(localized: "投喂"),
                systemImage: "brain.head.profile",
                filled: false,
                isPrimary: false,
                action: onFeed
            )
            dockDivider
            dockButton(
                title: String(localized: "足迹"),
                systemImage: "figure.walk",
                filled: false,
                isPrimary: primaryAction == .social,
                action: onFootprints
            )
        }
        .frame(maxWidth: KelinLayout.standardContentWidth)
        .frame(height: KelinSize.roomActionDockHeight)
        .background(.ultraThinMaterial)
        .background(KelinColor.surfacePrimary.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: KelinRadius.large)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.5), radius: 16, y: 8)
        .frame(maxWidth: .infinity)
    }

    private var isLeadingPrimary: Bool {
        switch primaryAction {
        case .chat, .recall, .history, .pact, .social:
            true
        }
    }

    private var leadingTitle: String {
        switch primaryAction {
        case .chat:
            String(localized: "说话")
        case .recall:
            String(localized: "叫它回来")
        case .history:
            String(localized: "查看历史")
        case .pact:
            String(localized: "查看契约")
        case .social:
            String(localized: "看行程")
        }
    }

    private var leadingSymbol: String {
        switch primaryAction {
        case .chat, .history:
            "bubble.left.fill"
        case .recall:
            "sparkles"
        case .pact:
            "book.closed.fill"
        case .social:
            "figure.walk"
        }
    }

    private var leadingAction: () -> Void {
        onPrimary
    }

    private var dockDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(width: 1, height: 24)
    }

    private func dockButton(
        title: String,
        systemImage: String,
        filled: Bool,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isPrimary {
                        Circle()
                            .fill(KelinColor.accent.opacity(0.1))
                            .frame(width: 32, height: 32)
                            .shadow(color: KelinColor.accent.opacity(0.2), radius: 6)
                    }
                    Image(systemName: systemImage)
                        .font(.system(size: filled ? 21 : 22, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 12, weight: isPrimary ? .medium : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: KelinSize.minimumTouchTarget)
            .foregroundStyle(isPrimary ? KelinColor.accent : KelinColor.textSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(String(localized: "房间底部动作"))
    }
}
