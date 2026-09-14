import Foundation

actor MockExtractService: ExtractServiceProtocol {
    private(set) var requests: [(clientID: UUID, conversationWindowID: UUID)] = []

    func extract(clientID: UUID, conversationWindowID: UUID) async throws -> ExtractResult {
        requests.append((clientID, conversationWindowID))
        return ExtractResult(
            status: .extracted,
            memories: [],
            patch: SessionPatch(
                snapshotVersion: 1,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                serverTime: Date(timeIntervalSince1970: 1_700_500_000)
            )
        )
    }
}
