import Foundation

actor APIMemoryService: MemoryServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) {
        self.client = client
    }

    func list(filter: MemoryFilter, cursor: String?, limit: Int = 30) async throws -> MemoryPage {
        let dto = try await client.send(
            .memories(filter: filter, cursor: cursor, limit: limit),
            responseType: MemoryPageDTO.self
        )
        return try MemoryMapper.mapPage(dto)
    }

    func correct(
        id: UUID,
        expectedVersion: Int,
        summary: String,
        clientID: UUID
    ) async throws -> MemoryMutation {
        try await sendMutation(
            .patch(
                "/memories/\(id.uuidString.lowercased())",
                body: APIDecoding.encodeBody(
                    MemoryPatchRequestDTO(
                        clientID: clientID,
                        expectedVersion: expectedVersion,
                        action: "correct",
                        summary: summary
                    )
                )
            )
        )
    }

    func seal(id: UUID, expectedVersion: Int, clientID: UUID) async throws -> MemoryMutation {
        try await sendMutation(
            .patch(
                "/memories/\(id.uuidString.lowercased())",
                body: APIDecoding.encodeBody(
                    MemoryPatchRequestDTO(
                        clientID: clientID,
                        expectedVersion: expectedVersion,
                        action: "seal",
                        summary: nil
                    )
                )
            )
        )
    }

    func delete(id: UUID, expectedVersion: Int, clientID: UUID) async throws -> MemoryMutation {
        try await sendMutation(
            .delete(
                "/memories/\(id.uuidString.lowercased())",
                body: APIDecoding.encodeBody(
                    MemoryDeleteRequestDTO(clientID: clientID, expectedVersion: expectedVersion)
                )
            )
        )
    }

    func clearAll(clientID: UUID) async throws -> MemoryMutation {
        try await sendMutation(
            .delete(
                "/memories",
                body: APIDecoding.encodeBody(
                    MemoryClearRequestDTO(
                        clientID: clientID,
                        confirm: MemoryMutationRules.clearConfirm
                    )
                )
            )
        )
    }

    private func sendMutation(_ endpoint: APIEndpoint) async throws -> MemoryMutation {
        let result = try await client.sendWithMetadata(
            endpoint,
            responseType: MutationResultDTO.self
        )
        return try MemoryMapper.mapMutation(result.payload, serverTime: result.serverTime)
    }
}
