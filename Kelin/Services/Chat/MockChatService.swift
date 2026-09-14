import Foundation

actor MockChatService: ChatServiceProtocol {
    struct Configuration: Sendable {
        var error: AppError?
        var delay: Duration?
        var snapshotVersion: Int

        static let success = Configuration(snapshotVersion: 1)
    }

    private var configuration: Configuration
    private(set) var requests: [(clientMessageID: UUID, content: String)] = []
    private var replyCount = 0

    init(configuration: Configuration = .success) {
        self.configuration = configuration
    }

    func setConfiguration(_ configuration: Configuration) {
        self.configuration = configuration
    }

    func recordedRequests() -> [(clientMessageID: UUID, content: String)] {
        requests
    }

    func sendMessage(
        clientMessageID: UUID,
        content: String,
        context: ChatSendContext,
        source: ChatMessage.Source
    ) async throws -> ChatTurnResult {
        if let delay = configuration.delay {
            try await Task.sleep(for: delay)
        }

        try Task.checkCancellation()

        let trimmed = try ChatOutboundRules.validateContent(content)

        if let error = configuration.error {
            throw error
        }

        requests.append((clientMessageID, trimmed))

        replyCount += 1
        let now = Date(timeIntervalSince1970: 1_700_200_000 + TimeInterval(replyCount))

        return ChatTurnResult(
            userMessage: ChatMessage(
                id: clientMessageID,
                clientID: clientMessageID,
                role: .user,
                content: trimmed,
                source: source,
                status: .accepted,
                createdAt: now
            ),
            spiritMessage: ChatMessage(
                id: UUID(uuidString: String(format: "30000000-0000-4000-8000-%012X", replyCount))!,
                clientID: UUID(uuidString: String(format: "30000000-0000-4000-8000-%012X", replyCount))!,
                role: .spirit,
                content: Self.stubSpiritReply(index: replyCount),
                source: .text,
                status: .generated,
                createdAt: now.addingTimeInterval(1)
            ),
            conversationWindowID: UUID(uuidString: "40000000-0000-4000-8000-000000000001")!,
            shouldExtract: replyCount.isMultiple(of: 3),
            usesStubProvider: true,
            patch: SessionPatch(
                snapshotVersion: configuration.snapshotVersion + replyCount,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                serverTime: now
            )
        )
    }

    private static func stubSpiritReply(index: Int) -> String {
        "stub-reply-\(index)"
    }
}
