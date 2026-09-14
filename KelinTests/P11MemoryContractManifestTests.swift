import XCTest
@testable import Kelin

final class P11MemoryContractManifestTests: XCTestCase {
    func testLiveOpenAPISHAIsFullLengthHex() {
        XCTAssertEqual(P11MemoryContractManifest.liveOpenAPISHA256.count, 64)
        XCTAssertTrue(
            P11MemoryContractManifest.liveOpenAPISHA256.unicodeScalars.allSatisfy {
                CharacterSet(charactersIn: "0123456789abcdef").contains($0)
            }
        )
    }

    func testMemoryControlEndpointsArePresent() {
        XCTAssertEqual(P11MemoryContractManifest.requiredEndpoints.count, 4)
        XCTAssertTrue(P11MemoryContractManifest.missingEndpoints.isEmpty)
        XCTAssertTrue(P11MemoryContractManifest.isLocked)
        XCTAssertEqual(P11MemoryContractManifest.statusWord, "待人工验收")
        XCTAssertTrue(P11MemoryContractManifest.generatedFixtureIDs.contains("memories.list.success"))
    }

    func testDocumentSHAAndLiveSHAAreBothRecorded() {
        XCTAssertEqual(P11MemoryContractManifest.documentReviewedSHA256.count, 64)
        XCTAssertNotEqual(
            P11MemoryContractManifest.liveOpenAPISHA256,
            P11MemoryContractManifest.documentReviewedSHA256
        )
        XCTAssertNotEqual(
            P11MemoryContractManifest.liveOpenAPISHA256,
            P11MemoryContractManifest.previousReviewedSHA256
        )
    }

    func testLiveMemoryPublicSchemaIsRecorded() {
        XCTAssertEqual(
            P11MemoryContractManifest.memoryPublicRequiredKeys,
            [
                "id",
                "type",
                "summary",
                "salience",
                "confidence",
                "status",
                "version",
                "created_at",
            ]
        )
        XCTAssertEqual(
            Set(P11MemoryContractManifest.memoryPublicTypeValues),
            ["preference", "knowledge", "emotion", "relation", "speech", "sight"]
        )
        XCTAssertEqual(
            Set(P11MemoryContractManifest.memoryPublicStatusValues),
            ["active", "sealed", "deleted"]
        )
    }
}
