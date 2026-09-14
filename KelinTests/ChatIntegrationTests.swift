import XCTest
@testable import Kelin

final class ChatIntegrationTests: XCTestCase {
    func testMessagesMapperReadsLiveSourceRefs() throws {
        let json = """
        {
          "ok": true,
          "data": {
            "items": [
              {
                "id": "10000000-0000-4000-8000-000000000002",
                "client_id": null,
                "role": "spirit",
                "content": "还记得。雨夜里的那盏。",
                "source": "text",
                "status": "generated",
                "reply_to_message_id": "10000000-0000-4000-8000-000000000001",
                "source_refs": [
                  {"type": "memory", "id": "50000000-0000-4000-8000-000000000001"},
                  {"type": "web", "url": "https://example.com/note", "fetched_at": "2026-09-10T08:00:00Z"}
                ],
                "created_at": "2026-09-10T08:00:02Z"
              }
            ],
            "next_cursor": null,
            "has_more": false,
            "snapshot_at": "2026-09-10T08:00:02Z"
          },
          "error": null,
          "request_id": "fixture-live-source-refs",
          "server_time": "2026-09-10T08:00:02Z"
        }
        """
        let envelope = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<MessagesPageDTO>.self,
            from: Data(json.utf8)
        )
        let page = try MessagesMapper.map(try XCTUnwrap(envelope.data))

        XCTAssertEqual(page.items[0].sourceRefs.map(\.kind), ["memory", "web"])
        XCTAssertEqual(
            page.items[0].sourceRefs[0].memoryID?.uuidString,
            "50000000-0000-4000-8000-000000000001"
        )
        XCTAssertEqual(page.items[0].sourceRefs[1].url, "https://example.com/note")
        XCTAssertEqual(page.items[0].sourceRefs[1].title, "example.com")
    }

    func testAPIMessagesServiceUsesMessagesPath() async throws {
        let client = MockAPIClient()
        await client.setResponse(
            MockAPIResponse(data: Data(MessagesDraftFixtures.firstPageEnvelope.utf8), statusCode: 200),
            forPath: "/messages?limit=30"
        )

        let service = APIMessagesService(client: client)
        let page = try await service.fetchMessages(cursor: nil, limit: 30)

        let paths = await client.requestedPaths
        XCTAssertEqual(paths, ["/messages?limit=30"])
        XCTAssertEqual(page.items.count, 2)
        XCTAssertTrue(page.hasMore)
    }

    func testAPIExtractServicePostsExtractAndReadsPatch() async throws {
        let client = MockAPIClient()
        await client.setResponse(
            MockAPIResponse(data: Data(ExtractDraftFixtures.successEnvelope.utf8), statusCode: 200),
            forPath: "/extract"
        )

        let service = APIExtractService(client: client)
        let result = try await service.extract(
            clientID: UUID(uuidString: "60000000-0000-4000-8000-000000000001")!,
            conversationWindowID: UUID(uuidString: "40000000-0000-4000-8000-000000000001")!
        )

        let paths = await client.requestedPaths
        XCTAssertEqual(paths, ["/extract"])
        XCTAssertEqual(result.status, .extracted)
        XCTAssertEqual(result.memories.count, 1)
        XCTAssertEqual(result.patch.snapshotVersion, 10)
        XCTAssertEqual(result.patch.memoriesUpsert.first?.summary, "希望被叫阿年")
        XCTAssertNil(result.patch.room)
        XCTAssertNil(result.patch.quotas)
    }

    func testChatMapperReadsProviderFlagAndSourceRefs() throws {
        let envelopeJSON = """
        {
          "ok": true,
          "data": {
            "resource": {
              "type": "chat_turn",
              "generation_source": "provider",
              "user_message": {
                "id": "10000000-0000-4000-8000-000000000001",
                "client_id": "20000000-0000-4000-8000-000000000001",
                "content": "今天过得怎么样"
              },
              "spirit_message": {
                "id": "10000000-0000-4000-8000-000000000002",
                "content": "还记得。雨夜里的那盏。",
                "source_refs": [
                  {"type": "memory", "id": "50000000-0000-4000-8000-000000000001"}
                ]
              },
              "conversation_window_id": "40000000-0000-4000-8000-000000000001",
              "should_extract": true,
              "usage": { "input_units": 12, "output_units": 8 }
            },
            "patch": {
              "snapshot_version": 9,
              "spirit": null,
              "room": null,
              "onboarding": null
            }
          },
          "error": null,
          "request_id": "fixture-chat-provider",
          "server_time": "2026-09-10T08:00:02Z"
        }
        """
        let envelope = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<ChatMutationResultDTO>.self,
            from: Data(envelopeJSON.utf8)
        )
        let result = try ChatMapper.mapChatTurnResult(
            try XCTUnwrap(envelope.data),
            serverTime: envelope.serverTime
        )

        XCTAssertFalse(result.usesStubProvider)
        XCTAssertTrue(result.shouldExtract)
        XCTAssertEqual(result.spiritMessage.sourceRefs.first?.kind, "memory")
        XCTAssertEqual(result.userMessage.clientID.uuidString, "20000000-0000-4000-8000-000000000001")
        XCTAssertNil(result.patch.room)
        XCTAssertNil(result.patch.quotas)
    }

    func testChatMapperReadsSiblingQuotasWithoutClearingNullRoom() throws {
        let envelopeJSON = """
        {
          "ok": true,
          "data": {
            "resource": {
              "type": "chat_turn",
              "generation_source": "provider",
              "user_message": {
                "id": "10000000-0000-4000-8000-000000000001",
                "content": "今天过得怎么样"
              },
              "spirit_message": {
                "id": "10000000-0000-4000-8000-000000000002",
                "content": "还记得。"
              },
              "conversation_window_id": "40000000-0000-4000-8000-000000000001",
              "should_extract": false,
              "usage": { "input_units": 12, "output_units": 8 }
            },
            "patch": {
              "snapshot_version": 11,
              "spirit": null,
              "room": null,
              "onboarding": null
            },
            "quotas": [
              {
                "capability": "chat",
                "used": 2,
                "limit": 100,
                "reset_at": "2026-09-12T16:00:00Z"
              }
            ]
          },
          "error": null,
          "request_id": "fixture-chat-quotas",
          "server_time": "2026-09-10T08:00:02Z"
        }
        """
        let envelope = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<ChatMutationResultDTO>.self,
            from: Data(envelopeJSON.utf8)
        )
        let result = try ChatMapper.mapChatTurnResult(
            try XCTUnwrap(envelope.data),
            serverTime: envelope.serverTime
        )

        XCTAssertNil(result.patch.room)
        XCTAssertEqual(result.patch.quotas?.first?.capability, .chat)
        XCTAssertEqual(result.patch.quotas?.first?.used, 2)
        XCTAssertEqual(result.patch.quotas?.first?.limit, 100)
    }

    func testInvalidCursorMapsToAppError() {
        let error = APIErrorMapper.map(
            APIErrorPayload(code: "INVALID_CURSOR", message: "", retryable: false),
            requestID: "cursor-1"
        )
        XCTAssertEqual(error, .invalidCursor)
    }
}
