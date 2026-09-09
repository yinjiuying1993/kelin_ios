import Foundation

actor APIBootstrapService: BootstrapServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchBootstrap() async throws -> BootstrapSnapshot {
        let result = try await client.sendWithMetadata(
            .get("/bootstrap"),
            responseType: BootstrapDataDTO.self
        )
        return try BootstrapMapper.map(result.payload, serverTime: result.serverTime)
    }
}
