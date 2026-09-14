import SwiftUI

struct RoomSpiritEntityView: View {
    let spiritName: String
    let scholarMarks: [String]
    let canvasSize: CGSize
    var onTap: () -> Void
    var onEyeMarkTap: (() -> Void)?
    var onScholarRuneTap: (() -> Void)?
    var dialogueLine: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let metrics = SpiritEntityMetrics.scaled(to: canvasSize)
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 30.0,
                paused: !RoomSpiritMotionRules.shouldRunLoop(
                    reduceMotion: reduceMotion,
                    isSceneActive: scenePhase == .active
                )
            )
        ) { context in
            spiritEntity(
                metrics: metrics,
                motion: RoomSpiritMotionRules.sample(at: context.date, reduceMotion: reduceMotion)
            )
        }
        .frame(width: metrics.width, height: metrics.height)
        .position(x: canvasSize.width * 0.5, y: canvasSize.height * 0.46)
    }

    private func spiritEntity(metrics: SpiritEntityMetrics, motion: RoomSpiritMotionSample) -> some View {
        ZStack {
            if let dialogueLine {
                spiritDialogueBubble(dialogueLine)
                    .offset(y: -(metrics.height * 0.5 + 40))
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }

            Ellipse()
                .fill(Color.black.opacity(0.6))
                .blur(radius: 10)
                .frame(width: metrics.shadowWidth, height: metrics.shadowHeight)
                .scaleEffect(motion.shadowScale)
                .opacity(motion.shadowOpacity)
                .offset(y: metrics.height * 0.42)

            ZStack {
                Button(action: onTap) {
                    spiritBody(metrics: metrics, motion: motion)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(RoomHotspotRules.accessibilityLabel(for: .spirit)) \(spiritName)")
                .accessibilityHint(RoomHotspotRules.accessibilityHint(for: .spirit))

                markHotspots(metrics: metrics)
            }
            .offset(y: motion.floatOffset)
        }
    }

    private func spiritBody(metrics: SpiritEntityMetrics, motion: RoomSpiritMotionSample) -> some View {
        ZStack {
            RoomSpiritSilhouette(radii: .halo)
                .fill(KelinColor.accent.opacity(0.10))
                .blur(radius: 24)
                .padding(-10)

            ZStack {
                RoomSpiritSilhouette()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: 0x222A3D).opacity(0.96),
                                Color(hex: 0x1A2030).opacity(0.94),
                                Color(hex: 0x121622).opacity(0.92),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoomSpiritSilhouette()
                    .fill(
                        RadialGradient(
                            colors: [.clear, .clear, Color.black.opacity(0.30)],
                            center: .center,
                            startRadius: metrics.width * 0.12,
                            endRadius: metrics.height * 0.52
                        )
                    )

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [KelinColor.accent, Color(hex: 0x6B5CD8), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: metrics.coreWidth, height: metrics.coreHeight)
                    .blur(radius: 16)
                    .scaleEffect(motion.coreScale)
                    .opacity(motion.coreOpacity)
                    .offset(y: -metrics.height * 0.02)

                faceFeatures(metrics: metrics)
            }
            .clipShape(RoomSpiritSilhouette())
            .overlay {
                RoomSpiritSilhouette()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
            .overlay {
                RoomSpiritSilhouette()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.14), .clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.35)
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.5), radius: 20, y: 16)
        }
        .frame(width: metrics.width, height: metrics.height)
    }

    private func faceFeatures(metrics: SpiritEntityMetrics) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                spiritEye(size: metrics.eyeSize)
                ZStack(alignment: .topTrailing) {
                    spiritEye(size: metrics.eyeSize)
                    Circle()
                        .fill(KelinColor.accentWarm)
                        .frame(width: metrics.markSize, height: metrics.markSize)
                        .shadow(color: KelinColor.accentWarm.opacity(0.85), radius: 4)
                        .offset(x: 14, y: -8)
                }
            }

            if !scholarMarks.isEmpty {
                scholarRuneBadge
            }
        }
        .offset(y: -metrics.height * 0.04)
        .allowsHitTesting(false)
    }

    private func markHotspots(metrics: SpiritEntityMetrics) -> some View {
        ZStack {
            Button(action: { onEyeMarkTap?() }) {
                Color.clear
                    .frame(
                        width: RoomHotspotRules.minimumTouchTarget,
                        height: RoomHotspotRules.minimumTouchTarget
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: 36, y: -metrics.height * 0.08)
            .accessibilityLabel(RoomHotspotRules.accessibilityLabel(for: .eyeMark))
            .accessibilityHint(RoomHotspotRules.accessibilityHint(for: .eyeMark))

            if !scholarMarks.isEmpty {
                Button(action: { onScholarRuneTap?() }) {
                    Color.clear
                        .frame(
                            width: max(96, RoomHotspotRules.minimumTouchTarget),
                            height: RoomHotspotRules.minimumTouchTarget
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .offset(y: metrics.height * 0.08)
                .accessibilityLabel(RoomHotspotRules.accessibilityLabel(for: .scholarRune))
                .accessibilityHint(RoomHotspotRules.accessibilityHint(for: .scholarRune))
            }
        }
    }

    private func spiritEye(size: CGFloat) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .shadow(color: .white.opacity(0.95), radius: 4.5)
            .shadow(color: Color(red: 0.78, green: 0.75, blue: 1).opacity(0.8), radius: 7)
    }

    private var scholarRuneBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(KelinColor.accent)
                .frame(width: 4, height: 4)
            Text(String(localized: "✧ STAR 学者纹"))
                .font(.system(size: 10, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(KelinColor.accent.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(KelinColor.accent.opacity(0.15))
        .clipShape(Capsule())
        .overlay {
            Capsule().stroke(KelinColor.accent.opacity(0.3), lineWidth: 1)
        }
        .accessibilityLabel(String(localized: "学者纹"))
    }

    private func spiritDialogueBubble(_ text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(KelinColor.accent)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(KelinColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, KelinSpacing.compact)
        .padding(.vertical, KelinSpacing.small)
        .background(KelinColor.surfacePrimary.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.standard))
        .overlay {
            RoundedRectangle(cornerRadius: KelinRadius.standard)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    }
}

private struct SpiritEntityMetrics {
    static let designWidth: CGFloat = 184
    static let designHeight: CGFloat = 224
    static let designCanvasWidth: CGFloat = 390

    let width: CGFloat
    let height: CGFloat
    let coreWidth: CGFloat
    let coreHeight: CGFloat
    let shadowWidth: CGFloat
    let shadowHeight: CGFloat
    let eyeSize: CGFloat
    let markSize: CGFloat

    static func scaled(to canvasSize: CGSize) -> SpiritEntityMetrics {
        let scale = min(1, canvasSize.width / (designCanvasWidth - KelinSpacing.pageHorizontal * 2))
        return SpiritEntityMetrics(
            width: designWidth * scale,
            height: designHeight * scale,
            coreWidth: 80 * scale,
            coreHeight: 112 * scale,
            shadowWidth: 112 * scale,
            shadowHeight: 20 * scale,
            eyeSize: 8,
            markSize: 8
        )
    }
}

/// 设计稿水滴/种子剪影：`border-radius: 50% 50% 43% 43% / 64% 64% 36% 36%`
private struct RoomSpiritSilhouette: Shape {
    var radii: Radii = .body

    struct Radii {
        let topX: CGFloat
        let topY: CGFloat
        let bottomX: CGFloat
        let bottomY: CGFloat

        static let body = Radii(topX: 0.50, topY: 0.64, bottomX: 0.43, bottomY: 0.36)
        static let halo = Radii(topX: 0.50, topY: 0.62, bottomX: 0.44, bottomY: 0.38)
    }

    func path(in rect: CGRect) -> Path {
        let top = CGSize(width: rect.width * radii.topX, height: rect.height * radii.topY)
        let bottom = CGSize(width: rect.width * radii.bottomX, height: rect.height * radii.bottomY)

        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        addEllipseArc(
            &path,
            center: CGPoint(x: rect.maxX - top.width, y: rect.minY + top.height),
            radius: top,
            from: 270,
            to: 360
        )
        addEllipseArc(
            &path,
            center: CGPoint(x: rect.maxX - bottom.width, y: rect.maxY - bottom.height),
            radius: bottom,
            from: 0,
            to: 90
        )
        addEllipseArc(
            &path,
            center: CGPoint(x: rect.minX + bottom.width, y: rect.maxY - bottom.height),
            radius: bottom,
            from: 90,
            to: 180
        )
        addEllipseArc(
            &path,
            center: CGPoint(x: rect.minX + top.width, y: rect.minY + top.height),
            radius: top,
            from: 180,
            to: 270
        )
        path.closeSubpath()
        return path
    }

    private func addEllipseArc(
        _ path: inout Path,
        center: CGPoint,
        radius: CGSize,
        from startDegrees: Double,
        to endDegrees: Double
    ) {
        let steps = 18
        for step in 1...steps {
            let progress = Double(step) / Double(steps)
            let degrees = startDegrees + (endDegrees - startDegrees) * progress
            let radians = degrees * .pi / 180
            path.addLine(
                to: CGPoint(
                    x: center.x + radius.width * CGFloat(cos(radians)),
                    y: center.y + radius.height * CGFloat(sin(radians))
                )
            )
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
