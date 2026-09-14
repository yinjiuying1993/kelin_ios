import XCTest
@testable import Kelin

final class P13GrowthContractManifestTests: XCTestCase {
    func testLiveOpenAPISHAIsFullLengthHex() {
        XCTAssertEqual(P13GrowthContractManifest.liveOpenAPISHA256.count, 64)
        XCTAssertTrue(
            P13GrowthContractManifest.liveOpenAPISHA256.unicodeScalars.allSatisfy {
                CharacterSet(charactersIn: "0123456789abcdef").contains($0)
            }
        )
    }

    func testT07DisplayContractIsLockedWithoutClientDelta() {
        XCTAssertEqual(P13GrowthContractManifest.taskID, "P13-T07")
        XCTAssertTrue(P13GrowthContractManifest.isLocked)
        XCTAssertEqual(P13GrowthContractManifest.statusWord, "待人工验收")
        XCTAssertFalse(P13GrowthContractManifest.allowsClientDelta)
        XCTAssertEqual(
            P13GrowthContractManifest.reviewedDocumentSHA256,
            "4297869e18a29e1ac9933f620def66dcfc8c902a504d380459eb6bc7ba961092"
        )
        XCTAssertEqual(
            P13GrowthContractManifest.liveOpenAPISHA256,
            "84f1849d536485ea819e0863adc86b1e9a213229d7dd6dd81f0f3ca7cd2abc95"
        )
        XCTAssertTrue(P13GrowthContractManifest.generatedFixtureIDs.isEmpty)
        XCTAssertTrue(P13GrowthContractManifest.missingEventTypeEnum)
        XCTAssertTrue(P13GrowthContractManifest.missingCatalogLocks.contains("MutationEvent.type enum"))
        XCTAssertTrue(P13GrowthContractManifest.missingCatalogLocks.contains("ai_usage"))
    }

    func testSpecEventWhitelistIsRecordedWithoutGuessingLiveNames() {
        XCTAssertEqual(
            P13GrowthContractManifest.specEventTypes,
            [
                "chat_completed",
                "feed_accepted",
                "promise_completed",
                "pact_answered",
                "pact_completed",
                "memory_added",
                "visit_completed",
                "returned_from_lost",
                "time_passed",
            ]
        )
        XCTAssertEqual(
            P13GrowthContractManifest.eventTypeConflicts,
            ["feed.accepted", "promise.completed"]
        )
        XCTAssertFalse(
            Set(P13GrowthContractManifest.specEventTypes)
                .isSuperset(of: P13GrowthContractManifest.liveObservedEventTypes)
        )
    }

    func testSpiritStageAndStatusMatchLiveSpiritPublic() {
        XCTAssertEqual(P13GrowthContractManifest.spiritStageValues, ["whelp", "formed", "awake"])
        XCTAssertEqual(P13GrowthContractManifest.spiritStatusValues, ["home", "away", "study", "lost"])
        XCTAssertTrue(P13GrowthContractManifest.presentReadOnlySpiritKeys.contains("scholar_marks"))
        XCTAssertTrue(P13GrowthContractManifest.specQuotaCapabilities.contains("food"))
        XCTAssertTrue(P13GrowthContractManifest.specQuotaCapabilities.contains("search"))
    }

    func testNoGrowthWriteEndpointsAreInvented() {
        XCTAssertFalse(P13GrowthContractManifest.presentPaths.contains { $0.contains("growth") })
        XCTAssertFalse(P13GrowthContractManifest.allowsClientDelta)
    }
}
