import XCTest
@testable import Kelin

final class FeedMapperTests: XCTestCase {
    func testFoodSuccessMapsQuotaAndDoesNotInventVitals() throws {
        let dto = try APIDecoding.makeJSONDecoder().decode(
            FeedMutationResultDTO.self,
            from: Data(FeedDraftFixtures.foodSuccessJSON.utf8)
        )
        let mutation = try FeedMapper.map(dto, serverTime: nil)

        XCTAssertEqual(mutation.resource.kind, "food")
        XCTAssertEqual(mutation.resource.status, "accepted")
        XCTAssertEqual(mutation.quotas.first?.capability, .food)
        XCTAssertEqual(mutation.quotas.first?.used, 1)
        XCTAssertEqual(mutation.patch.quotas?.first?.capability, .food)
        XCTAssertNil(mutation.patch.spirit)
        XCTAssertEqual(mutation.events.first?.type, "feed.accepted")
    }

    func testKnowledgeSuccessMapsMemoryUpsert() throws {
        let dto = try APIDecoding.makeJSONDecoder().decode(
            FeedMutationResultDTO.self,
            from: Data(FeedDraftFixtures.knowledgeSuccessJSON.utf8)
        )
        let mutation = try FeedMapper.map(dto, serverTime: nil)

        XCTAssertEqual(mutation.patch.memoriesUpsert.first?.type, "knowledge")
        XCTAssertEqual(mutation.patch.memoriesUpsert.first?.summary, "STAR 法则")
        XCTAssertEqual(mutation.patch.quotas, [])
    }

    func testOmittedQuotasLeavePatchQuotasNil() throws {
        let json = """
        {
          "resource": {
            "type": "feed",
            "id": "61000000-0000-4000-8000-000000000001",
            "version": 1,
            "kind": "food",
            "status": "accepted"
          },
          "patch": {
            "snapshot_version": 12
          }
        }
        """
        let dto = try APIDecoding.makeJSONDecoder().decode(
            FeedMutationResultDTO.self,
            from: Data(json.utf8)
        )
        let mutation = try FeedMapper.map(dto, serverTime: nil)

        XCTAssertNil(mutation.patch.quotas)
        XCTAssertTrue(mutation.quotas.isEmpty)
    }

    func testLocationRejectedIsStillSuccessEnvelope() throws {
        let dto = try APIDecoding.makeJSONDecoder().decode(
            FeedMutationResultDTO.self,
            from: Data(FeedDraftFixtures.locationRejectedJSON.utf8)
        )
        let mutation = try FeedMapper.map(dto, serverTime: nil)

        XCTAssertEqual(mutation.resource.status, "rejected")
        XCTAssertTrue(mutation.patch.memoriesUpsert.isEmpty)
        XCTAssertEqual(mutation.quotas.first?.capability, .sight)
    }

    func testUploadTicketRequiresFourSegmentPath() throws {
        let dto = try APIDecoding.makeJSONDecoder().decode(
            SightUploadURLResultDTO.self,
            from: Data(FeedDraftFixtures.uploadSuccessJSON.utf8)
        )
        let ticket = try FeedMapper.mapUpload(dto)

        XCTAssertEqual(ticket.method, "PUT")
        XCTAssertEqual(ticket.uploadSessionID, FeedDraftFixtures.uploadSessionID)
        XCTAssertTrue(FeedPresentationRules.isFourSegmentSightPath(ticket.objectPath))
    }

    func testPromiseCompleteKeepsEventType() throws {
        let dto = try APIDecoding.makeJSONDecoder().decode(
            FeedMutationResultDTO.self,
            from: Data(FeedDraftFixtures.promiseCompleteJSON.utf8)
        )
        let mutation = try FeedMapper.map(dto, serverTime: nil)

        XCTAssertEqual(mutation.resource.promiseStatus, "completed")
        XCTAssertEqual(mutation.events.first?.type, "promise.completed")
    }

    func testLocationRequestOmitsCoordinates() throws {
        let data = try FeedEncoding.encodeBody(
            FeedSightLocationRequestDTO(
                clientID: UUID(uuidString: "61000000-0000-4000-8000-000000000099")!,
                payload: FeedSightLocationPayloadDTO(
                    label: "外滩",
                    city: "上海",
                    category: "landmark"
                )
            )
        )
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let payload = try XCTUnwrap(object["payload"] as? [String: Any])
        XCTAssertEqual(payload["source"] as? String, "location")
        XCTAssertEqual(payload["label"] as? String, "外滩")
        XCTAssertEqual(payload["city"] as? String, "上海")
        XCTAssertNil(payload["latitude"])
        XCTAssertNil(payload["longitude"])
        XCTAssertNil(payload["address"])
    }
}
