import CoreGraphics
import Foundation

struct RoomSpiritMotionSample: Equatable, Sendable {
    let floatOffset: CGFloat
    let coreScale: CGFloat
    let coreOpacity: Double
    let shadowScale: CGFloat
    let shadowOpacity: Double

    static let resting = RoomSpiritMotionSample(
        floatOffset: 0,
        coreScale: 0.96,
        coreOpacity: 0.55,
        shadowScale: 1,
        shadowOpacity: 0.6
    )
}

enum RoomSpiritMotionRules {
    static let floatPeriod: TimeInterval = 5
    static let pulsePeriod: TimeInterval = 4.5
    static let shadowPeriod: TimeInterval = 5
    static let floatAmplitude: CGFloat = 8

    static func sample(at date: Date, reduceMotion: Bool) -> RoomSpiritMotionSample {
        guard !reduceMotion else {
            return .resting
        }

        let timestamp = date.timeIntervalSinceReferenceDate
        let floatProgress = oscillationProgress(timestamp, period: floatPeriod)
        let pulseProgress = oscillationProgress(timestamp, period: pulsePeriod)
        let shadowProgress = oscillationProgress(timestamp, period: shadowPeriod)

        return RoomSpiritMotionSample(
            floatOffset: -floatAmplitude * floatProgress,
            coreScale: lerp(from: 0.96, to: 1.06, progress: pulseProgress),
            coreOpacity: lerp(from: 0.55, to: 0.95, progress: pulseProgress),
            shadowScale: lerp(from: 1.0, to: 0.88, progress: shadowProgress),
            shadowOpacity: lerp(from: 0.6, to: 0.35, progress: shadowProgress)
        )
    }

    static func shouldRunLoop(reduceMotion: Bool, isSceneActive: Bool) -> Bool {
        !reduceMotion && isSceneActive
    }

    private static func oscillationProgress(_ timestamp: TimeInterval, period: TimeInterval) -> CGFloat {
        guard period > 0 else { return 0 }
        let cycle = timestamp / period
        let fractional = cycle - floor(cycle)
        let radians = fractional * 2 * Double.pi
        return CGFloat((sin(radians - Double.pi / 2) + 1) / 2)
    }

    private static func lerp(from start: Double, to end: Double, progress: CGFloat) -> Double {
        start + (end - start) * Double(progress)
    }

    private static func lerp(from start: CGFloat, to end: CGFloat, progress: CGFloat) -> CGFloat {
        start + (end - start) * progress
    }
}
