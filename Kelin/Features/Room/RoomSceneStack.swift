import SwiftUI

struct RoomSceneStack: View {
    let scene: RoomSceneModel
    let spiritName: String
    let scholarMarks: [String]
    var dialogueLine: String?
    var onSpiritTap: () -> Void = {}
    var onEyeMarkTap: (() -> Void)?
    var onScholarRuneTap: (() -> Void)?
    var onFootprintTap: (() -> Void)?
    var onBookshelfTap: (() -> Void)?
    var onArtifactTap: (() -> Void)?
    var onPaperNoteTap: (() -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoomWeatherLayer(weather: scene.weather)

                if scene.primaryState == .home {
                    RoomHomeEnvironmentView(
                        scene: scene,
                        canvasSize: geometry.size,
                        onFootprintTap: onFootprintTap,
                        onBookshelfTap: onBookshelfTap,
                        onArtifactTap: onArtifactTap,
                        onPaperNoteTap: onPaperNoteTap
                    )
                } else {
                    legacyEnvironment(state: scene.primaryState, canvasSize: geometry.size)
                }

                if let pendingSight = scene.pendingSight {
                    RoomPendingSightLayer(
                        presentation: pendingSight,
                        canvasSize: geometry.size
                    )
                }

                if scene.spiritVisible {
                    RoomSpiritEntityView(
                        spiritName: spiritName,
                        scholarMarks: scholarMarks,
                        canvasSize: geometry.size,
                        onTap: onSpiritTap,
                        onEyeMarkTap: onEyeMarkTap,
                        onScholarRuneTap: onScholarRuneTap,
                        dialogueLine: dialogueLine
                    )
                }

                RoomStateAccentLayer(state: scene.primaryState, canvasSize: geometry.size)

                if scene.primaryState != .home, scene.letter != nil || scene.unreadFootprints > 0 {
                    RoomLetterFootprintLayer(
                        letter: scene.letter,
                        unreadFootprints: scene.unreadFootprints,
                        canvasSize: geometry.size
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .opacity(scene.dimmingFactor)
        }
    }

    @ViewBuilder
    private func legacyEnvironment(state: SpiritStatus, canvasSize: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: KelinRadius.large)
                .fill(KelinColor.surfaceSecondary.opacity(0.55))
                .frame(width: canvasSize.width * 0.92, height: canvasSize.height * 0.18)
                .position(x: canvasSize.width * 0.5, y: canvasSize.height * 0.82)

            if state == .study {
                RoundedRectangle(cornerRadius: KelinRadius.small)
                    .fill(KelinColor.accentSurface)
                    .frame(width: canvasSize.width * 0.22, height: canvasSize.height * 0.08)
                    .overlay {
                        Image(systemName: "book.pages")
                            .foregroundStyle(KelinColor.accent)
                    }
                    .position(x: canvasSize.width * 0.22, y: canvasSize.height * 0.58)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct RoomWeatherLayer: View {
    let weather: RoomWeather

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
        .opacity(0.35)
        .allowsHitTesting(false)
    }

    private var gradientColors: [Color] {
        switch weather {
        case .cloudy, .unknown:
            [Color.white.opacity(0.08), .clear]
        case .rain:
            [KelinColor.accentCold.opacity(0.18), .clear]
        case .clear:
            [KelinColor.accentWarm.opacity(0.12), .clear]
        case .snow:
            [Color.white.opacity(0.14), .clear]
        }
    }
}

private struct RoomPendingSightLayer: View {
    let presentation: PendingSightPresentation
    let canvasSize: CGSize

    var body: some View {
        RoundedRectangle(cornerRadius: KelinRadius.standard)
            .fill(KelinColor.accentSurface.opacity(0.9))
            .frame(width: canvasSize.width * 0.2, height: canvasSize.height * 0.12)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(KelinColor.accent)
            }
            .position(x: canvasSize.width * 0.28, y: canvasSize.height * 0.34)
            .allowsHitTesting(false)
            .accessibilityLabel(String(localized: "见闻处理中"))
    }
}

private struct RoomStateAccentLayer: View {
    let state: SpiritStatus
    let canvasSize: CGSize

    var body: some View {
        Group {
            switch state {
            case .home, .study:
                EmptyView()
            case .away:
                Image(systemName: "wind")
                    .font(.system(size: KelinIconSize.navigation, weight: .medium))
                    .foregroundStyle(KelinColor.accentCold.opacity(0.85))
                    .position(x: canvasSize.width * 0.84, y: canvasSize.height * 0.42)
            case .lost:
                ZStack {
                    Color.black.opacity(0.18)
                    RoundedRectangle(cornerRadius: KelinRadius.small)
                        .stroke(KelinColor.accent.opacity(0.65), lineWidth: 1)
                        .background(KelinColor.accentSurface.opacity(0.35))
                        .frame(width: canvasSize.width * 0.16, height: canvasSize.height * 0.12)
                        .overlay {
                            Image(systemName: "lamp.desk")
                                .foregroundStyle(KelinColor.accent)
                        }
                        .position(x: canvasSize.width * 0.72, y: canvasSize.height * 0.68)
                    RoundedRectangle(cornerRadius: KelinRadius.small)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: canvasSize.width * 0.34, height: canvasSize.height * 0.16)
                        .position(x: canvasSize.width * 0.78, y: canvasSize.height * 0.24)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct RoomLetterFootprintLayer: View {
    let letter: RoomLetter?
    let unreadFootprints: Int
    let canvasSize: CGSize

    var body: some View {
        ZStack {
            if let letter {
                Text(letter.displayTitle)
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, KelinSpacing.compact)
                    .padding(.vertical, KelinSpacing.small)
                    .frame(maxWidth: canvasSize.width * 0.42, alignment: .leading)
                    .background(KelinColor.surfacePrimary.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small))
                    .overlay {
                        RoundedRectangle(cornerRadius: KelinRadius.small)
                            .stroke(KelinColor.borderSubtle, lineWidth: 1)
                    }
                    .position(x: canvasSize.width * 0.34, y: canvasSize.height * 0.74)
                    .accessibilityLabel(letter.displayTitle)
            }
            if unreadFootprints > 0 {
                HStack(spacing: KelinSpacing.xSmall) {
                    Image(systemName: "footprints")
                    Text("\(unreadFootprints)")
                        .kelinTypography(KelinTypography.label)
                }
                .padding(.horizontal, KelinSpacing.compact)
                .padding(.vertical, KelinSpacing.xSmall)
                .background(KelinColor.surfaceSecondary.opacity(0.95))
                .clipShape(Capsule())
                .position(x: canvasSize.width * 0.84, y: canvasSize.height * 0.72)
            }
        }
        .allowsHitTesting(false)
    }
}
