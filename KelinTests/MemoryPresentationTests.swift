import XCTest
@testable import Kelin

final class MemoryPresentationTests: XCTestCase {
    func testRelationshipFilterMapsThreeTypes() {
        XCTAssertEqual(
            MemoryPresentationRules.relationshipTypes,
            ["preference", "relation", "emotion"]
        )
        XCTAssertTrue(MemoryPresentationRules.matches(sample(type: "preference"), filter: .relationship))
        XCTAssertTrue(MemoryPresentationRules.matches(sample(type: "relation"), filter: .relationship))
        XCTAssertTrue(MemoryPresentationRules.matches(sample(type: "emotion"), filter: .relationship))
        XCTAssertFalse(MemoryPresentationRules.matches(sample(type: "knowledge"), filter: .relationship))
        XCTAssertFalse(MemoryPresentationRules.matches(sample(type: "preference", status: "sealed"), filter: .all))
    }

    func testCalendarGroupsTodayYesterdayWeekAndEarlier() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 10, hour: 15))!

        let today = sample(type: "preference", createdAt: now)
        let yesterday = sample(
            type: "sight",
            summary: "雨夜里的一盏路灯",
            createdAt: calendar.date(byAdding: .day, value: -1, to: now)!
        )
        let thisWeek = sample(
            type: "knowledge",
            summary: "STAR 法则",
            createdAt: calendar.date(from: DateComponents(year: 2026, month: 9, day: 8, hour: 10))!
        )
        let earlier = sample(
            type: "speech",
            createdAt: calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        )

        let groups = MemoryPresentationRules.groups(
            from: [earlier, thisWeek, yesterday, today],
            filter: .all,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(groups.map(\.section), [.today, .yesterday, .thisWeek, .earlier])
        XCTAssertEqual(groups[0].items.first?.memory.summary, "不要叫宝宝，要叫阿年")
        XCTAssertEqual(groups[1].items.first?.impactTitle, "窗台摆件")
        XCTAssertEqual(groups[2].items.first?.typeTitle, "知识")
        XCTAssertEqual(groups[3].items.first?.typeTitle, "口癖")
    }

    func testFilterTitlesMatchS07() {
        XCTAssertEqual(
            MemoryFilter.allCases.map(\.title),
            ["全部", "偏好与关系", "知识", "口癖", "见闻"]
        )
    }

    private func sample(
        type: String,
        summary: String = "不要叫宝宝，要叫阿年",
        status: String = "active",
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> MemorySummary {
        MemorySummary(
            id: UUID(),
            type: type,
            summary: summary,
            status: status,
            createdAt: createdAt
        )
    }
}
