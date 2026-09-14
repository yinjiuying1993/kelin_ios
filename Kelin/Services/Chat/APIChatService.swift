import Foundation

actor APIChatService: ChatServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) {
        self.client = client
    }

    func sendMessage(
        clientMessageID: UUID,
        content: String,
        context: ChatSendContext,
        source: ChatMessage.Source
    ) async throws -> ChatTurnResult {
        let trimmed = try ChatOutboundRules.validateContent(content)
        let request = ChatMapper.makeRequest(
            clientMessageID: clientMessageID,
            content: trimmed,
            context: context,
            onboarding: false,
            source: source.rawValue
        )
        let body = try APIDecoding.encodeBody(request)
        let result = try await client.sendWithMetadata(
            .post("/chat", body: body, timeout: APIEndpoint.chatPOSTTimeout),
            responseType: ChatMutationResultDTO.self
        )
        return try ChatMapper.mapChatTurnResult(result.payload, serverTime: result.serverTime)
    }
}
