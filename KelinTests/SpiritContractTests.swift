import XCTest
@testable import Kelin

final class SpiritContractTests: XCTestCase {
    private let decoder = APIDecoding.makeJSONDecoder()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    func testCreateSpiritRequestEncodesSnakeCaseFields() throws {
        let request = CreateSpiritRequest(
            clientID: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
            egg: .warm,
            name: "未名",
            consents: sampleConsents()
        )

        let dto = SpiritMapper.mapRequest(request)
        let data = try encoder.encode(dto)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(json.contains("\"client_id\""))
        XCTAssertTrue(json.contains("\"ai_disclosure\""))
        XCTAssertTrue(json.contains("\"document_version\""))
        XCTAssertTrue(json.contains("\"explicitly_accepted\""))
        XCTAssertTrue(json.contains("\"warm\""))
    }

    func testSuccessFixtureDecodesWarmColdWildTraits() throws {
        for egg in EggType.allCases {
            let envelope: APIEnvelope<MutationResultDTO> = try decode(
                P05CreateSpiritFixtures.successEnvelope(egg: egg)
            )

            let mutation = try XCTUnwrap(envelope.data)
            let result = try SpiritMapper.mapCreateSpiritResult(mutation)

            XCTAssertEqual(result.spirit.egg, egg)
            XCTAssertEqual(result.onboarding.step, 0)
            XCTAssertEqual(result.snapshotVersion, 1)
            assertInitialTraits(result.spirit.traits, for: egg)
        }
    }

    func testErrorEnvelopeWithoutOkAndObjectDetailsDecodes() throws {
        let json = """
        {
          "data": null,
          "error": {
            "code": "INVALID_INPUT",
            "message": "validation failed",
            "retryable": false,
            "details": {
              "consents.data_notice.displayed": ["Input should be true"]
            }
          },
          "request_id": "req-invalid-displayed",
          "server_time": "2026-09-09T09:10:00.123Z"
        }
        """

        let envelope: APIEnvelope<MutationResultDTO> = try decode(json)

        XCTAssertFalse(envelope.ok)
        XCTAssertEqual(envelope.error?.code, "INVALID_INPUT")
        XCTAssertEqual(envelope.error?.details?["consents.data_notice.displayed"], "Input should be true")
        XCTAssertEqual(
            APIErrorMapper.map(try XCTUnwrap(envelope.error), requestID: envelope.requestID),
            .invalidInput
        )
    }

    func testBusinessErrorFixtureMapsToConflict() throws {
        let envelope: APIEnvelope<MutationResultDTO> = try decode(
            P05CreateSpiritFixtures.businessErrorEnvelope
        )

        XCTAssertFalse(envelope.ok)
        let errorPayload = try XCTUnwrap(envelope.error)
        XCTAssertEqual(
            APIErrorMapper.map(errorPayload, requestID: envelope.requestID),
            .conflict
        )
    }

    func testMissingRequiredFieldFailsDecoding() throws {
        XCTAssertThrowsError(
            try decode(P05CreateSpiritFixtures.missingRequiredFieldEnvelope) as APIEnvelope<MutationResultDTO>
        )
    }

    func testMockHatchServiceReturnsConfiguredEggTraits() async throws {
        let service = MockHatchService()
        await service.setMode(.success(.cold))

        let result = try await service.createSpirit(sampleCreateRequest(egg: .cold))

        XCTAssertEqual(result.spirit.egg, .cold)
        assertInitialTraits(result.spirit.traits, for: .cold)

        let requests = await service.recordedRequests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.egg, .cold)
    }

    func testMockHatchServicePropagatesBusinessError() async throws {
        let service = MockHatchService()
        await service.setMode(.businessError(.conflict))

        do {
            _ = try await service.createSpirit(sampleCreateRequest(egg: .warm))
            XCTFail("Expected conflict")
        } catch let error as AppError {
            XCTAssertEqual(error, .conflict)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func decode<T: Decodable>(_ json: String) throws -> T {
        try decoder.decode(T.self, from: Data(json.utf8))
    }

    private func sampleConsents() -> CreateSpiritConsents {
        CreateSpiritConsents(
            aiDisclosure: .init(documentVersion: "2026-09", explicitlyAccepted: true),
            dataNotice: .init(documentVersion: "2026-09", displayed: true),
            userTerms: .init(documentVersion: "2026-09", displayed: true)
        )
    }

    private func sampleCreateRequest(egg: EggType) -> CreateSpiritRequest {
        CreateSpiritRequest(
            clientID: UUID(uuidString: "00000000-0000-0000-0000-000000000031")!,
            egg: egg,
            name: "未名",
            consents: sampleConsents()
        )
    }

    private func assertInitialTraits(_ traits: TraitValues, for egg: EggType) {
        switch egg {
        case .warm:
            XCTAssertEqual(traits.closeness, 65)
            XCTAssertEqual(traits.curiosity, 55)
            XCTAssertEqual(traits.sharpness, 35)
            XCTAssertEqual(traits.nocturnal, 40)
            XCTAssertEqual(traits.stubborn, 40)
        case .cold:
            XCTAssertEqual(traits.closeness, 35)
            XCTAssertEqual(traits.curiosity, 45)
            XCTAssertEqual(traits.sharpness, 70)
            XCTAssertEqual(traits.nocturnal, 60)
            XCTAssertEqual(traits.stubborn, 55)
        case .wild:
            XCTAssertEqual(traits.closeness, 50)
            XCTAssertEqual(traits.curiosity, 50)
            XCTAssertEqual(traits.sharpness, 50)
            XCTAssertEqual(traits.nocturnal, 50)
            XCTAssertEqual(traits.stubborn, 50)
        }
    }
}
