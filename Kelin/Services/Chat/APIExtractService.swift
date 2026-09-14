import Foundation

actor APIExtractService: ExtractServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) {
        self.client = client
    }

    func extract(clientID: UUID, conversationWindowID: UUID) async throws -> ExtractResult {
        let body = try APIDecoding.encodeBody(
            ExtractMapper.makeRequest(clientID: clientID, conversationWindowID: conversationWindowID)
        )
        let result = try await client.sendWithMetadata(
            .post("/extract", body: body, timeout: APIEndpoint.extractPOSTTimeout),
            responseType: ExtractMutationResultDTO.self
        )
        return try ExtractMapper.map(result.payload, serverTime: result.serverTime)
    }
}
