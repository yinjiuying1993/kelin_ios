import XCTest
@testable import Kelin

final class RoomSpiritMotionTests: XCTestCase {
    func testReduceMotionUsesStaticRestingPose() {
        let sample = RoomSpiritMotionRules.sample(
            at: Date(timeIntervalSinceReferenceDate: 123.456),
            reduceMotion: true
        )

        XCTAssertEqual(sample, .resting)
        XCTAssertEqual(sample.floatOffset, 0)
    }

    func testMotionSampleChangesOverTimeWhenAllowed() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let later = Date(timeIntervalSinceReferenceDate: RoomSpiritMotionRules.floatPeriod / 2)

        let first = RoomSpiritMotionRules.sample(at: start, reduceMotion: false)
        let second = RoomSpiritMotionRules.sample(at: later, reduceMotion: false)

        XCTAssertNotEqual(first.floatOffset, second.floatOffset)
        XCTAssertNotEqual(first.coreScale, second.coreScale)
    }

    func testShouldRunLoopOnlyWhenActiveAndMotionAllowed() {
        XCTAssertFalse(RoomSpiritMotionRules.shouldRunLoop(reduceMotion: true, isSceneActive: true))
        XCTAssertFalse(RoomSpiritMotionRules.shouldRunLoop(reduceMotion: false, isSceneActive: false))
        XCTAssertTrue(RoomSpiritMotionRules.shouldRunLoop(reduceMotion: false, isSceneActive: true))
    }

    func testFloatOffsetNeverExceedsDesignAmplitude() {
        for step in 0...20 {
            let date = Date(timeIntervalSinceReferenceDate: Double(step) * 0.37)
            let sample = RoomSpiritMotionRules.sample(at: date, reduceMotion: false)
            XCTAssertGreaterThanOrEqual(sample.floatOffset, -RoomSpiritMotionRules.floatAmplitude - 0.001)
            XCTAssertLessThanOrEqual(sample.floatOffset, 0.001)
        }
    }
}
