import XCTest
@testable import Kelin

final class P12FeedContractManifestTests: XCTestCase {
    func testLiveOpenAPISHAIsFullLengthHex() {
        XCTAssertEqual(P12FeedContractManifest.liveOpenAPISHA256.count, 64)
        XCTAssertTrue(
            P12FeedContractManifest.liveOpenAPISHA256.unicodeScalars.allSatisfy {
                CharacterSet(charactersIn: "0123456789abcdef").contains($0)
            }
        )
    }

    func testFeedEndpointsArePresentAndLocked() {
        XCTAssertEqual(P12FeedContractManifest.requiredEndpoints.count, 6)
        XCTAssertTrue(P12FeedContractManifest.missingEndpoints.isEmpty)
        XCTAssertTrue(P12FeedContractManifest.isLocked)
        XCTAssertEqual(P12FeedContractManifest.statusWord, "待人工验收")
        XCTAssertFalse(P12FeedContractManifest.photoLiveReady)
        XCTAssertTrue(P12FeedContractManifest.generatedFixtureIDs.contains("feed.food.success"))
    }

    func testDocumentSHAAndLiveSHAAreBothRecorded() {
        XCTAssertEqual(
            P12FeedContractManifest.liveOpenAPISHA256,
            "84f1849d536485ea819e0863adc86b1e9a213229d7dd6dd81f0f3ca7cd2abc95"
        )
        XCTAssertEqual(
            P12FeedContractManifest.documentReviewedSHA256,
            "4297869e18a29e1ac9933f620def66dcfc8c902a504d380459eb6bc7ba961092"
        )
        XCTAssertNotEqual(
            P12FeedContractManifest.liveOpenAPISHA256,
            P12FeedContractManifest.documentReviewedSHA256
        )
    }

    func testRequiredKindsAndStatusesMatchLiveSchema() {
        XCTAssertEqual(
            P12FeedContractManifest.requiredKinds,
            ["food", "knowledge", "emotion", "promise", "sight"]
        )
        XCTAssertEqual(
            Set(P12FeedContractManifest.requiredStatuses),
            ["pending", "processing", "accepted", "rejected", "cancelled"]
        )
        XCTAssertTrue(P12FeedContractManifest.locationCategories.contains("landmark"))
        XCTAssertTrue(P12FeedContractManifest.sightPropWhitelist.contains("lamp"))
    }
}
