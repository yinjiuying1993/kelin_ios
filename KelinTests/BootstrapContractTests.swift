import XCTest
@testable import Kelin

final class BootstrapContractTests: XCTestCase {
    private let decoder = APIDecoding.makeJSONDecoder()

    func testNewUserFixtureDecodesExplicitNullSpiritAndRoom() throws {
        let snapshot = try mapEnvelope(P06BootstrapFixtures.newUserEnvelope)

        XCTAssertNil(snapshot.spirit)
        XCTAssertNil(snapshot.room)
        XCTAssertEqual(snapshot.onboarding.step, 0)
        XCTAssertTrue(snapshot.onboarding.required)
        XCTAssertEqual(snapshot.snapshotVersion, 0)
        XCTAssertEqual(snapshot.report.status, .locked)
    }

    func testOnboardingUserFixtureDecodesSpiritRoomAndQuotas() throws {
        let snapshot = try mapEnvelope(P06BootstrapFixtures.onboardingUserEnvelope)

        XCTAssertEqual(snapshot.spirit?.egg, .warm)
        XCTAssertEqual(snapshot.room?.weather, "cloudy")
        XCTAssertEqual(snapshot.onboarding.step, 3)
        XCTAssertEqual(snapshot.quotas.count, 1)
        XCTAssertEqual(snapshot.quotas.first?.capability, .chat)
        XCTAssertEqual(snapshot.snapshotVersion, 12)
    }

    func testFullUserFixtureDecodesCompletedOnboardingAndRoomLayers() throws {
        let snapshot = try mapEnvelope(P06BootstrapFixtures.fullUserEnvelope)

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
            P06BootstrapFixtures.unknownReportStatusEnvelope
        )

        XCTAssertThrowsError(try BootstrapMapper.map(envelope)) { error in
            XCTAssertEqual(error as? AppError, .decoding)
        }
    }

    func testMissingRequiredFieldFailsDecoding() throws {
        XCTAssertThrowsError(
            try decode(P06BootstrapFixtures.missingRequiredFieldEnvelope) as APIEnvelope<BootstrapDataDTO>
        )
    }

    func testServerTimeComesFromEnvelope() throws {
        let snapshot = try mapEnvelope(P06BootstrapFixtures.fullUserEnvelope)

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
