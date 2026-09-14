import Foundation

actor APIPactService: PactServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) {
        self.client = client
    }

    func createPact(
        theme: String,
        title: String,
        notesMemoryID: UUID?,
        clientID: UUID
    ) async throws -> PactMutation {
        let body = try PactCacheRules.encodeCreateBody(
            theme: theme,
            title: title,
            clientID: clientID,
            notesMemoryID: notesMemoryID
        )
        let result = try await client.sendWithMetadata(
            .post("/pacts", body: body),
            responseType: PactCreateResultDTO.self
        )
        return try PactMapper.mapCreate(result.payload, serverTime: result.serverTime)
    }

    func createSession(pactID: UUID, clientID: UUID) async throws -> PactMutation {
        let body = try APIDecoding.encodeBody(
            PactSessionRequestDTO(clientID: clientID, pactID: pactID)
        )
        let result = try await client.sendWithMetadata(
            .post("/pact-session", body: body),
            responseType: PactSessionResultDTO.self
        )
        return try PactMapper.mapSessionResult(result.payload, serverTime: result.serverTime)
    }

    func submitAnswer(
        sessionID: UUID,
        expectedSessionVersion: Int,
        questionID: String,
        text: String,
        clientID: UUID
    ) async throws -> PactMutation {
        let body = try APIDecoding.encodeBody(
            PactAnswerRequestDTO(
                clientID: clientID,
                sessionID: sessionID,
                expectedSessionVersion: expectedSessionVersion,
                questionID: questionID,
                text: text
            )
        )
        let result = try await client.sendWithMetadata(
            .post("/pact-answer", body: body),
            responseType: PactAnswerResultDTO.self
        )
        return try PactMapper.mapAnswerResult(result.payload, serverTime: result.serverTime)
    }

    func skipToday(pactID: UUID, sessionDate: String, clientID: UUID) async throws -> PactMutation {
        let body = try APIDecoding.encodeBody(
            PactSkipRequestDTO(clientID: clientID, pactID: pactID, sessionDate: sessionDate)
        )
        let result = try await client.sendWithMetadata(
            .post("/pact-skip", body: body),
            responseType: PactSkipResultDTO.self
        )
        return try PactMapper.mapSkip(result.payload, serverTime: result.serverTime)
    }
}
