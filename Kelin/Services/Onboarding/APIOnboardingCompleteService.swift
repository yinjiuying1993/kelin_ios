import Foundation

actor APIOnboardingCompleteService: OnboardingCompleteServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func completeOnboarding(
        clientID: UUID,
        expectedSpiritVersion: Int
    ) async throws -> OnboardingCompleteResult {
        let body = try APIDecoding.encodeBody(
            OnboardingCompleteRequestDTO(
                clientID: clientID,
                expectedSpiritVersion: expectedSpiritVersion
            )
        )
        let mutation = try await client.send(
            .post("/onboarding/complete", body: body),
            responseType: MutationResultDTO.self
        )
        return try OnboardingCompleteMapper.map(mutation)
    }
}
