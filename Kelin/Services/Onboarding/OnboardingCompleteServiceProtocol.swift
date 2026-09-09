import Foundation

struct OnboardingCompleteResult: Equatable, Sendable {
    let onboarding: OnboardingState
    let room: RoomSnapshot?
    let snapshotVersion: Int
}

protocol OnboardingCompleteServiceProtocol: Sendable {
    func completeOnboarding(
        clientID: UUID,
        expectedSpiritVersion: Int
    ) async throws -> OnboardingCompleteResult
}
