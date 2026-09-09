import Foundation

actor MockOnboardingChatService: OnboardingChatServiceProtocol {
    struct Configuration: Sendable {
        var error: AppError?
        var delay: Duration?

        static let success = Configuration()
    }

    private var configuration: Configuration
    private(set) var requests: [(clientMessageID: UUID, content: String, completedRounds: Int)] = []

    init(configuration: Configuration = .success) {
        self.configuration = configuration
    }

    func setConfiguration(_ configuration: Configuration) {
        self.configuration = configuration
    }

    func recordedRequests() -> [(clientMessageID: UUID, content: String, completedRounds: Int)] {
        requests
    }

    func sendOnboardingMessage(
        clientMessageID: UUID,
        content: String,
        completedRounds: Int
    ) async throws -> OnboardingChatResult {
        if let delay = configuration.delay {
            try await Task.sleep(for: delay)
        }

        try Task.checkCancellation()

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.invalidInput
        }

        requests.append((clientMessageID, trimmed, completedRounds))

        if let error = configuration.error {
            throw error
        }

        guard completedRounds < OnboardingConversationDefaults.totalSteps else {
            throw AppError.invalidInput
        }

        let nextRound = completedRounds + 1
        let spiritText = Self.stubSpiritReply(round: nextRound)

        return OnboardingChatResult(
            userMessage: OnboardingMessage(id: clientMessageID, role: .user, text: trimmed),
            spiritMessage: OnboardingMessage(role: .spirit, text: spiritText),
            completedRounds: nextRound,
            snapshotVersion: nextRound,
            usesStubProvider: true
        )
    }

    private static func stubSpiritReply(round: Int) -> String {
        switch round {
        case 1:
            String(localized: "……你刚才说，雨声很好听？")
        case 2:
            String(localized: "嗯。那你会在雨里停一下吗？")
        case 3:
            String(localized: "我好像能想象那个画面。")
        case 4:
            String(localized: "你说话的方式，有点慢。")
        default:
            String(localized: "我记住了。")
        }
    }
}
