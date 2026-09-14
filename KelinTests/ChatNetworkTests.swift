import XCTest
@testable import Kelin

final class ChatNetworkTests: XCTestCase {
    func testOrdinaryChatRequestIsNotOnboarding() {
        let context = ChatSendContext(
            timezone: "Asia/Shanghai",
            localHour: 23,
            weather: "rain",
            city: "上海"
        )
        let request = ChatMapper.makeRequest(
            clientMessageID: UUID(uuidString: "20000000-0000-4000-8000-000000000001")!,
            content: "亮着。今天还下雨了。",
            context: context,
            onboarding: false
        )

        XCTAssertFalse(request.onboarding)
        XCTAssertEqual(request.source, "text")
        let voice = ChatMapper.makeRequest(
            clientMessageID: UUID(uuidString: "20000000-0000-4000-8000-000000000002")!,
            content: "亮着。今天还下雨了。",
            context: context,
            onboarding: false,
            source: "voice"
        )
        XCTAssertEqual(voice.source, "voice")
        XCTAssertNotEqual(voice.clientMessageID, request.clientMessageID)
        XCTAssertEqual(request.context.weather, "rain")
        XCTAssertEqual(request.context.city, "上海")
        XCTAssertEqual(request.context.localHour, 23)
    }

    func testMapChatTurnResultReadsWindowAndStubFlag() throws {
        let envelope = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<ChatMutationResultDTO>.self,
            from: Data(ChatDraftFixtures.ordinarySuccessEnvelope.utf8)
        )
        let result = try ChatMapper.mapChatTurnResult(
            try XCTUnwrap(envelope.data),
            serverTime: envelope.serverTime
        )

        XCTAssertEqual(result.conversationWindowID.uuidString, "40000000-0000-4000-8000-000000000001")
        XCTAssertFalse(result.shouldExtract)
        XCTAssertTrue(result.usesStubProvider)
        XCTAssertEqual(result.patch.snapshotVersion, 8)
        XCTAssertNil(result.patch.room)
        XCTAssertNil(result.patch.quotas)
        XCTAssertEqual(result.spiritMessage.content, "雨下得大的时候，屋檐下会很安静。")
    }

    func testAPIChatServiceUsesPostedChatPath() async throws {
        let client = MockAPIClient()
        await client.setResponse(
            MockAPIResponse(data: Data(ChatDraftFixtures.ordinarySuccessEnvelope.utf8), statusCode: 200),
            forPath: "/chat"
        )

        let service = APIChatService(client: client)
        let result = try await service.sendMessage(
            clientMessageID: UUID(uuidString: "20000000-0000-4000-8000-000000000001")!,
            content: "亮着。今天还下雨了。",
            context: ChatSendContext.make(weather: "cloudy"),
            source: .text
        )

        let paths = await client.requestedPaths
        XCTAssertEqual(paths, ["/chat"])
        XCTAssertEqual(result.userMessage.status, .accepted)
        XCTAssertEqual(result.spiritMessage.status, .generated)
    }

    func testAPIChatServicePropagatesTimeoutWithoutInventingReply() async throws {
        let client = MockAPIClient()
        await client.setError(.timedOut, forPath: "/chat")

        let service = APIChatService(client: client)
        do {
            _ = try await service.sendMessage(
                clientMessageID: UUID(uuidString: "20000000-0000-4000-8000-000000000002")!,
                content: "超时测试",
                context: ChatSendContext.make(weather: nil),
                source: .text
            )
            XCTFail("Expected timeout")
        } catch let error as AppError {
            XCTAssertEqual(error, .timedOut)
        }
    }
}
