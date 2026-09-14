import XCTest
@testable import Kelin

final class ChatTimelineRulesTests: XCTestCase {
    func testYesterdayNightLabel() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents(year: 2026, month: 9, day: 9, hour: 23, minute: 30)
        let yesterdayNight = calendar.date(from: components)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 10, hour: 10))!

        XCTAssertEqual(
            ChatTimelineRules.dayDividerLabel(for: yesterdayNight, now: now, calendar: calendar),
            String(localized: "昨天夜里")
        )
    }

    func testTimelineInsertsDayDividerOncePerDay() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let dayOne = MessagesDraftFixtures.sampleMessage(index: 1, createdAt: base)
        let dayOneLater = MessagesDraftFixtures.sampleMessage(index: 2, createdAt: base.addingTimeInterval(60))
        let dayTwo = MessagesDraftFixtures.sampleMessage(
            index: 3,
            createdAt: base.addingTimeInterval(86_400)
        )

        let items = ChatTimelineRules.timelineItems(from: [dayOne, dayOneLater, dayTwo], now: dayTwo.createdAt)

        let dividers = items.compactMap { item -> String? in
            if case let .dayDivider(label) = item { return label }
            return nil
        }
        let messages = items.compactMap { item -> ChatMessage? in
            if case let .message(message) = item { return message }
            return nil
        }

        XCTAssertEqual(dividers.count, 1)
        XCTAssertEqual(messages.count, 3)
    }

    func testChat1BubbleWidthRatios() {
        XCTAssertEqual(ChatLayout.spiritMaxWidthRatio, 0.78)
        XCTAssertEqual(ChatLayout.userMaxWidthRatio, 0.72)
        XCTAssertEqual(ChatLayout.headerHeight, 48)
        XCTAssertEqual(ChatLayout.composerControl, 44)
        XCTAssertEqual(ChatLayout.composerInnerHeight, 44)
        XCTAssertEqual(ChatLayout.bubbleVerticalPadding, 14)
        XCTAssertEqual(ChatLayout.voiceHoldHeight, 52)
        XCTAssertEqual(ChatLayout.voiceHoldCornerRadius, 14)
        XCTAssertEqual(ChatLayout.voiceHoldMaxWidth, 289)
        XCTAssertEqual(ChatLayout.voiceModeButtonWidth, 48)
        XCTAssertEqual(ChatLayout.voiceModeButtonCornerRadius, 16)
        XCTAssertEqual(ChatLayout.waveformHUDMaxWidth, 270)
        XCTAssertEqual(ChatLayout.waveformHUDHeight, 48)
        XCTAssertEqual(ChatLayout.waveformBarCount, 9)
        XCTAssertEqual(ChatLayout.waveformBarWidth, 3)
    }
}
