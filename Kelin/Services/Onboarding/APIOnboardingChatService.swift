import Foundation

actor APIOnboardingChatService: OnboardingChatServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func sendOnboardingMessage(
        clientMessageID: UUID,
        content: String,
        completedRounds: Int
    ) async throws -> OnboardingChatResult {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.invalidInput
        }

        guard completedRounds < OnboardingConversationDefaults.totalSteps else {
            throw AppError.invalidInput
        }

        let request = ChatMapper.makeRequest(clientMessageID: clientMessageID, content: trimmed)
        let body = try APIDecoding.encodeBody(request)
        let mutation = try await client.send(
            .post("/chat", body: body),
            responseType: ChatMutationResultDTO.self
        )
        return try ChatMapper.mapOnboardingChatResult(mutation)
    }
}
