import XCTest
@testable import Kelin

final class P15PactContractManifestTests: XCTestCase {
    func testLiveOpenAPISHAIsStillTheCapturedP14Surface() {
        XCTAssertEqual(P15PactContractManifest.liveOpenAPISHA256.count, 64)
        XCTAssertEqual(
            P15PactContractManifest.liveOpenAPISHA256,
            "75f505f062674495cde0a3401ef82dcab3e278a4223119ca9e84b64863059bbd"
        )
        XCTAssertEqual(
            P15PactContractManifest.documentReviewedSHA256,
            "743b462becbdce5d2ea062632e776318277c05c36007bfa718867e40bad0bb27"
        )
        XCTAssertNotEqual(
            P15PactContractManifest.liveOpenAPISHA256,
            P15PactContractManifest.documentReviewedSHA256
        )
    }

    func testT07StaysBlockedUntilLiveGainsPactRoutes() {
        XCTAssertEqual(P15PactContractManifest.taskID, "P15-T07")
        XCTAssertEqual(P15PactContractManifest.statusWord, "Mock完成-契约阻塞")
        XCTAssertFalse(P15PactContractManifest.isLocked)
        XCTAssertFalse(P15PactContractManifest.liveHasPactWriteRoutes)
        XCTAssertFalse(P15PactContractManifest.liveRoutesMatchDocument)
        XCTAssertEqual(P15PactContractManifest.missingEndpoints.count, 4)
        XCTAssertTrue(P15PactContractManifest.missingFixtureIDs.isEmpty)
        XCTAssertTrue(P15PactContractManifest.missingCatalogLocks.contains("live OpenAPI SHA mismatch"))
    }

    func testDocumentForbidsIndependentCompleteAndClientScore() {
        XCTAssertFalse(P15PactContractManifest.allowsIndependentComplete)
        XCTAssertFalse(P15PactContractManifest.allowsClientCompleteEndpoint)
        XCTAssertFalse(P15PactContractManifest.allowsClientScore)
        XCTAssertFalse(P15PactContractManifest.liveHasForbiddenPactComplete)
        XCTAssertFalse(P15PactContractManifest.presentPaths.contains { $0.lowercased().contains("pact") })
    }
}
