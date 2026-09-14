import Foundation

actor MockPactService: PactServiceProtocol {
    func createPact(
        theme: String,
        title: String,
        notesMemoryID: UUID?,
        clientID: UUID
    ) async throws -> PactMutation {
        _ = (theme, title, notesMemoryID, clientID)
        return try PactMapper.mapCreate(
            PactContractFixtures.decode(PactContractFixtures.createSuccess, as: PactCreateResultDTO.self),
            serverTime: Date(timeIntervalSince1970: 1_778_630_400)
        )
    }

    func createSession(pactID: UUID, clientID: UUID) async throws -> PactMutation {
        _ = (pactID, clientID)
        return try PactMapper.mapSessionResult(
            PactContractFixtures.decode(PactContractFixtures.sessionSuccess, as: PactSessionResultDTO.self),
            serverTime: Date(timeIntervalSince1970: 1_778_630_400)
        )
    }

    func submitAnswer(
        sessionID: UUID,
        expectedSessionVersion: Int,
        questionID: String,
        text: String,
        clientID: UUID
    ) async throws -> PactMutation {
        _ = (sessionID, questionID, text, clientID)
        let json = expectedSessionVersion >= 3
            ? PactContractFixtures.answerFinalized
            : PactContractFixtures.answerIncremental
        return try PactMapper.mapAnswerResult(
            PactContractFixtures.decode(json, as: PactAnswerResultDTO.self),
            serverTime: Date(timeIntervalSince1970: 1_778_630_400)
        )
    }

    func skipToday(pactID: UUID, sessionDate: String, clientID: UUID) async throws -> PactMutation {
        _ = (pactID, sessionDate, clientID)
        return try PactMapper.mapSkip(
            PactContractFixtures.decode(PactContractFixtures.skipSuccess, as: PactSkipResultDTO.self),
            serverTime: Date(timeIntervalSince1970: 1_778_630_400)
        )
    }
}
