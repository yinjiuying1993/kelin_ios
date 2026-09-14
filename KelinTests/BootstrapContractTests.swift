import XCTest
@testable import Kelin

final class BootstrapContractTests: XCTestCase {
    private let decoder = APIDecoding.makeJSONDecoder()

    func testNewUserFixtureDecodesExplicitNullSpiritAndRoom() throws {
        let snapshot = try mapEnvelope(BootstrapDraftFixtures.newUserEnvelope)

        XCTAssertNil(snapshot.spirit)
        XCTAssertNil(snapshot.room)
        XCTAssertEqual(snapshot.onboarding.step, 0)
        XCTAssertTrue(snapshot.onboarding.required)
        XCTAssertEqual(snapshot.snapshotVersion, 0)
        XCTAssertEqual(snapshot.report.status, .locked)
    }

    func testOnboardingUserFixtureDecodesSpiritRoomAndQuotas() throws {
        let snapshot = try mapEnvelope(BootstrapDraftFixtures.onboardingUserEnvelope)

        XCTAssertEqual(snapshot.spirit?.egg, .warm)
        XCTAssertEqual(snapshot.room?.weather, "cloudy")
        XCTAssertEqual(snapshot.onboarding.step, 3)
        XCTAssertEqual(snapshot.quotas.count, 1)
        XCTAssertEqual(snapshot.quotas.first?.capability, .chat)
        XCTAssertEqual(snapshot.snapshotVersion, 12)
    }

    func testFullUserFixtureDecodesCompletedOnboardingAndRoomLayers() throws {
        let snapshot = try mapEnvelope(BootstrapDraftFixtures.fullUserEnvelope)

        XCTAssertEqual(snapshot.spirit?.name, "雾生")
        XCTAssertEqual(snapshot.spirit?.stage, .formed)
        XCTAssertFalse(snapshot.onboarding.required)
        XCTAssertEqual(snapshot.onboarding.step, 5)
        XCTAssertNotNil(snapshot.onboarding.completedAt)
        XCTAssertEqual(snapshot.room?.layers.count, 1)
        XCTAssertEqual(snapshot.room?.layers.first?.key, "floor")
        XCTAssertEqual(snapshot.quotas.count, 2)
        XCTAssertEqual(snapshot.snapshotVersion, 184)
    }

    func testUnknownReportStatusFailsMapping() throws {
        let envelope: APIEnvelope<BootstrapDataDTO> = try decode(
            BootstrapDraftFixtures.unknownReportStatusEnvelope
        )

        XCTAssertThrowsError(try BootstrapMapper.map(envelope)) { error in
            XCTAssertEqual(error as? AppError, .decoding)
        }
    }

    func testMissingRequiredFieldFailsDecoding() throws {
        XCTAssertThrowsError(
            try decode(BootstrapDraftFixtures.missingRequiredFieldEnvelope) as APIEnvelope<BootstrapDataDTO>
        )
    }

    func testLiveSpiritPublicBootstrapDecodesWithoutLegacyFields() throws {
        let snapshot = try mapEnvelope(BootstrapDraftFixtures.liveSpiritPublicEnvelope)

        XCTAssertEqual(snapshot.spirit?.name, "未名")
        XCTAssertEqual(snapshot.spirit?.egg, .warm)
        XCTAssertEqual(snapshot.spirit?.version, 1)
        XCTAssertEqual(snapshot.spirit?.createdAt, snapshot.spirit?.updatedAt)
        XCTAssertEqual(snapshot.room?.weather, "cloudy")
        XCTAssertEqual(snapshot.room?.layers, [])
        XCTAssertEqual(snapshot.onboarding.step, 0)
        XCTAssertEqual(snapshot.onboarding.totalSteps, 5)
        XCTAssertEqual(snapshot.schemaVersion, 2)
        XCTAssertNotNil(snapshot.serverTime)
    }

    func testParsesMicrosecondOffsetTimestamps() {
        XCTAssertNotNil(APIDecoding.parseDate("2026-09-09T10:27:00.123456+00:00"))
        XCTAssertNotNil(APIDecoding.parseDate("2026-09-09T10:27:00.123456Z"))
        XCTAssertNotNil(APIDecoding.parseDate("2026-09-09T10:27:00+00:00"))
        XCTAssertNotNil(APIDecoding.parseDate("2026-09-09T10:27:00Z"))
    }

    func testServerTimeComesFromEnvelope() throws {
        let snapshot = try mapEnvelope(BootstrapDraftFixtures.fullUserEnvelope)

        XCTAssertEqual(
            snapshot.serverTime,
            ISO8601DateFormatter().date(from: "2026-09-07T03:46:00Z")
        )
    }

    private func mapEnvelope(_ json: String) throws -> BootstrapSnapshot {
        let envelope: APIEnvelope<BootstrapDataDTO> = try decode(json)
        return try BootstrapMapper.map(envelope)
    }

    private func decode<T: Decodable>(_ json: String) throws -> T {
        try decoder.decode(T.self, from: Data(json.utf8))
    }
}
