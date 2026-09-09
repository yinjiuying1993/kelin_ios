import Foundation

actor APIHatchService: HatchServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func createSpirit(_ request: CreateSpiritRequest) async throws -> CreateSpiritResult {
        let body = try APIDecoding.encodeBody(SpiritMapper.mapRequest(request))
        let mutation = try await client.send(
            .post("/spirits", body: body),
            responseType: MutationResultDTO.self
        )
        return try SpiritMapper.mapCreateSpiritResult(mutation)
    }
}
