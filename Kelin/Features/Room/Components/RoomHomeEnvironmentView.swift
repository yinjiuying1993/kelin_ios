import SwiftUI

struct RoomHomeEnvironmentView: View {
    let scene: RoomSceneModel
    let canvasSize: CGSize
    var onFootprintTap: (() -> Void)?
    var onBookshelfTap: (() -> Void)?
    var onArtifactTap: (() -> Void)?
    var onPaperNoteTap: (() -> Void)?

    var body: some View {
        ZStack {
            archedWindow
            doorway
            bookshelf
            windowsillArtifact
            if scene.unreadFootprints > 0 {
                doorwayFootprint
            }
            if scene.letter != nil || scene.primaryState == .home {
                paperNote
            }
        }
        .allowsHitTesting(scene.primaryState == .home)
    }

    private var archedWindow: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: canvasSize.width * 0.13, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x182133).opacity(0.25), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: canvasSize.width * 0.13, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
            Rectangle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 1, height: canvasSize.height * 0.22)
            Rectangle()
                .fill(Color.white.opacity(0.04))
                .frame(width: canvasSize.width * 0.16, height: 1)
        }
        .frame(width: canvasSize.width * 0.27, height: canvasSize.height * 0.34)
        .position(x: canvasSize.width * 0.22, y: canvasSize.height * 0.22)
    }

    private var bookshelf: some View {
        Button(action: { onBookshelfTap?() }) {
            VStack(spacing: KelinSpacing.xSmall) {
                HStack(alignment: .bottom, spacing: 6) {
                    bookSpine(width: 12, height: 32, accent: KelinColor.accentWarm)
                    bookSpine(width: 10, height: 28, accent: KelinColor.accent)
                    bookSpine(width: 14, height: 36, accent: KelinColor.accentCold, glow: true)
                    bookSpine(width: 12, height: 24, accent: Color.white.opacity(0.2))
                        .rotationEffect(.degrees(-6))
                }
                .padding(.horizontal, KelinSpacing.small)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: 0x1A2030))
                    .frame(height: 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .frame(
            minWidth: RoomHotspotRules.minimumTouchTarget,
            minHeight: RoomHotspotRules.minimumTouchTarget
        )
        .frame(width: canvasSize.width * 0.31)
        .contentShape(Rectangle())
        .position(x: canvasSize.width * 0.2, y: canvasSize.height * 0.58)
        .accessibilityLabel(RoomHotspotRules.accessibilityLabel(for: .bookshelf))
        .accessibilityHint(RoomHotspotRules.accessibilityHint(for: .bookshelf))
    }

    private var windowsillArtifact: some View {
        Button(action: { onArtifactTap?() }) {
            ZStack {
                Circle()
                    .fill(KelinColor.accentWarm.opacity(0.15))
                    .blur(radius: 9)
                    .frame(width: 40, height: 40)
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: 0x1E273B).opacity(0.9))
                        .frame(width: 20, height: 32)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(KelinColor.accentWarm.opacity(0.3), lineWidth: 1)
                        }
                        .overlay {
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(KelinColor.accentWarm.opacity(0.8))
                                    .frame(width: 10, height: 10)
                                    .shadow(color: KelinColor.accentWarm.opacity(0.8), radius: 4)
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(
                                        LinearGradient(
                                            colors: [KelinColor.accentWarm.opacity(0.4), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 6, height: 12)
                            }
                        }
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 28, height: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(
            minWidth: RoomHotspotRules.minimumTouchTarget,
            minHeight: RoomHotspotRules.minimumTouchTarget
        )
        .contentShape(Rectangle())
        .position(x: canvasSize.width * 0.26, y: canvasSize.height * 0.42)
        .accessibilityLabel(RoomHotspotRules.accessibilityLabel(for: .artifact))
        .accessibilityHint(RoomHotspotRules.accessibilityHint(for: .artifact))
    }

    private var doorway: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.black.opacity(0.4), Color(hex: 0x131724).opacity(0.2), .clear],
                    startPoint: .trailing,
                    endPoint: .leading
                )
            )
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 1)
            }
            .frame(width: canvasSize.width * 0.2, height: canvasSize.height * 0.74)
            .position(x: canvasSize.width * 0.88, y: canvasSize.height * 0.42)
    }

    private var doorwayFootprint: some View {
        Button(action: { onFootprintTap?() }) {
            VStack(spacing: 4) {
                ZStack {
                    Ellipse()
                        .fill(KelinColor.accent.opacity(0.25))
                        .frame(width: 32, height: 16)
                        .overlay {
                            Ellipse()
                                .stroke(KelinColor.accent.opacity(0.4), lineWidth: 1)
                        }
                        .rotationEffect(.degrees(-18))
                        .shadow(color: KelinColor.accent.opacity(0.4), radius: 7)
                    Circle()
                        .fill(KelinColor.accent.opacity(0.5))
                        .frame(width: 10, height: 10)
                        .offset(x: 8, y: -8)
                }
                Text(String(localized: "门口足迹"))
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
        .frame(
            minWidth: RoomHotspotRules.minimumTouchTarget,
            minHeight: RoomHotspotRules.minimumTouchTarget
        )
        .contentShape(Rectangle())
        .position(x: canvasSize.width * 0.78, y: canvasSize.height * 0.72)
        .accessibilityLabel(RoomHotspotRules.accessibilityLabel(for: .footprint))
        .accessibilityHint(RoomHotspotRules.accessibilityHint(for: .footprint))
    }

    private var paperNote: some View {
        Button(action: { onPaperNoteTap?() }) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: 0x1A202D))
                        .frame(width: 48, height: 28)
                        .overlay {
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        }
                        .overlay(alignment: .leading) {
                            VStack(alignment: .leading, spacing: 3) {
                                Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1)
                                Capsule().fill(KelinColor.accentWarm.opacity(0.6)).frame(width: 20, height: 1.5)
                                Capsule().fill(KelinColor.textSecondary.opacity(0.4)).frame(width: 12, height: 1)
                            }
                            .padding(.horizontal, 8)
                        }
                        .rotationEffect(.degrees(-3))
                    Circle()
                        .fill(KelinColor.accentWarm)
                        .frame(width: 8, height: 8)
                        .shadow(color: KelinColor.accentWarm.opacity(0.8), radius: 3)
                        .offset(x: 4, y: -4)
                }
                Text(String(localized: "地上字条"))
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
        .frame(
            minWidth: RoomHotspotRules.minimumTouchTarget,
            minHeight: RoomHotspotRules.minimumTouchTarget
        )
        .contentShape(Rectangle())
        .position(x: canvasSize.width * 0.5, y: canvasSize.height * 0.82)
        .accessibilityLabel(scene.letter?.displayTitle ?? RoomHotspotRules.accessibilityLabel(for: .paperNote))
        .accessibilityHint(RoomHotspotRules.accessibilityHint(for: .paperNote))
    }

    private func bookSpine(width: CGFloat, height: CGFloat, accent: Color, glow: Bool = false) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: 0x1E273B))
                .frame(width: width, height: height)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(accent.opacity(0.6))
                        .frame(width: 2)
                }
            if glow {
                Circle()
                    .fill(KelinColor.accentWarm.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .blur(radius: 1)
                    .offset(y: -4)
            }
        }
    }
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
