import Foundation

protocol PactServiceProtocol: Sendable {
    func createPact(
        theme: String,
        title: String,
        notesMemoryID: UUID?,
        clientID: UUID
    ) async throws -> PactMutation

    func createSession(pactID: UUID, clientID: UUID) async throws -> PactMutation

    func submitAnswer(
        sessionID: UUID,
        expectedSessionVersion: Int,
        questionID: String,
        text: String,
        clientID: UUID
    ) async throws -> PactMutation

    func skipToday(pactID: UUID, sessionDate: String, clientID: UUID) async throws -> PactMutation
}
