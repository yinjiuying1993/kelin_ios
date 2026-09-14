import XCTest
@testable import Kelin

final class FeedPresentationTests: XCTestCase {
    func testEmotionTitlesMatchS06() {
        XCTAssertEqual(
            FeedEmotion.allCases.map(\.title),
            ["平静", "开心", "疲惫", "焦虑", "生气"]
        )
    }

    func testKnowledgeBounds() {
        XCTAssertThrowsError(try FeedPresentationRules.validateKnowledge(""))
        XCTAssertThrowsError(try FeedPresentationRules.validateKnowledge(String(repeating: "记", count: 10_001)))
        XCTAssertEqual(try FeedPresentationRules.validateKnowledge("STAR"), "STAR")
    }

    func testLocationRejectsEmptyAndKeepsNoCoordinates() throws {
        XCTAssertThrowsError(try FeedPresentationRules.validateLocation(city: "", label: "外滩", category: nil))
        let location = try FeedPresentationRules.validateLocation(
            city: "上海",
            label: "外滩",
            category: .landmark
        )
        XCTAssertEqual(location.city, "上海")
        XCTAssertEqual(location.label, "外滩")
        XCTAssertEqual(location.category, "landmark")
    }

    func testSightPathMustBeFourSegments() {
        XCTAssertTrue(
            FeedPresentationRules.isFourSegmentSightPath(
                "sight-temp/11111111-1111-4111-8111-111111111111/22222222-2222-4222-8222-222222222222/33333333-3333-4333-8333-333333333333.jpg"
            )
        )
        XCTAssertFalse(FeedPresentationRules.isFourSegmentSightPath("sight/user/feed.jpg"))
    }

    func testSightUploadHostRejectsPlaceholderAndLoopback() {
        XCTAssertFalse(
            FeedPresentationRules.isReachableSightUploadHost(
                URL(string: "https://kelin.invalid/put")!
            )
        )
        XCTAssertFalse(
            FeedPresentationRules.isReachableSightUploadHost(
                URL(string: "http://127.0.0.1:9000/put")!
            )
        )
        XCTAssertTrue(
            FeedPresentationRules.isReachableSightUploadHost(
                URL(string: "https://example.supabase.co/storage/v1/object/sign/sight")!
            )
        )
    }

    func testFoodQuotaUsesSpecShapedEmptyCopy() {
        XCTAssertEqual(FeedPresentationRules.foodQuotaText(from: []), "今日 0/3")
    }

    func testFoodQuotaIgnoresNonFoodCapabilities() {
        let quotas = [
            QuotaEntry(
                capability: .sight,
                used: 1,
                limit: 3,
                resetAt: Date(timeIntervalSince1970: 1_700_000_000)
            )
        ]
        XCTAssertEqual(FeedPresentationRules.foodQuotaText(from: quotas), "今日 0/3")
    }
}
