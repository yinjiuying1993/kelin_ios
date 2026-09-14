import XCTest
@testable import Kelin

final class KelinLogTests: XCTestCase {
    func testShortIDUsesFirstEightHexCharacters() {
        let id = UUID(uuidString: "A1B2C3D4-0000-0000-0000-0000000000B1")!

        XCTAssertEqual(KelinLog.shortID(id), "a1b2c3d4")
    }

    func testSnapshotSummaryOmitsNamesAndMessageText() throws {
        let envelope: APIEnvelope<BootstrapDataDTO> = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<BootstrapDataDTO>.self,
            from: Data(BootstrapDraftFixtures.fullUserEnvelope.utf8)
        )
        let snapshot = try BootstrapMapper.map(
            try XCTUnwrap(envelope.data),
            serverTime: envelope.serverTime
        )
        let summary = KelinLog.snapshotSummary(snapshot)

        XCTAssertTrue(summary.contains("spirit="))
        XCTAssertTrue(summary.contains("step="))
        XCTAssertFalse(summary.contains("雾生"))
        XCTAssertFalse(summary.contains("access_token"))
        XCTAssertFalse(summary.contains("Bearer"))
    }

    func testAppErrorDiagnosticCodeDoesNotEmbedRequestID() {
        let error = AppError.unknown(requestID: "synthetic-request-id")

        XCTAssertEqual(error.diagnosticCode, "UNKNOWN")
        XCTAssertEqual(error.diagnosticRequestID, "synthetic-request-id")
    }

    func testConsoleOmitsDebugUnlessVerbose() {
        XCTAssertFalse(KelinLog.shouldPrintToConsole(.debug, verbose: false))
        XCTAssertTrue(KelinLog.shouldPrintToConsole(.info, verbose: false))
        XCTAssertTrue(KelinLog.shouldPrintToConsole(.error, verbose: false))
        XCTAssertTrue(KelinLog.shouldPrintToConsole(.debug, verbose: true))
    }

    func testSuccessfulGETIsDebugAndWriteIsInfo() {
        XCTAssertEqual(KelinLog.apiSuccessLevel(method: "GET", path: "/bootstrap"), .debug)
        XCTAssertEqual(KelinLog.apiSuccessLevel(method: "GET", path: "/messages?limit=30"), .debug)
        XCTAssertEqual(KelinLog.apiSuccessLevel(method: "POST", path: "/chat"), .info)
        XCTAssertEqual(KelinLog.apiSuccessLevel(method: "POST", path: "/extract"), .info)
    }
}
