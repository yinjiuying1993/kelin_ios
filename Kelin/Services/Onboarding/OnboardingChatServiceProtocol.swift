import Foundation

protocol OnboardingChatServiceProtocol: Sendable {
    func sendOnboardingMessage(
        clientMessageID: UUID,
        content: String,
        completedRounds: Int
    ) async throws -> OnboardingChatResult
}
