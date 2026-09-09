import Foundation

actor MockOnboardingCompleteService: OnboardingCompleteServiceProtocol {
    struct Configuration: Sendable {
        var error: AppError?
        var delay: Duration?
        var completedAt: Date

        init(
            error: AppError? = nil,
            delay: Duration? = nil,
            completedAt: Date = Date(timeIntervalSince1970: 1_700_020_000)
        ) {
            self.error = error
            self.delay = delay
            self.completedAt = completedAt
        }

        static func success(completedAt: Date = Date(timeIntervalSince1970: 1_700_020_000)) -> Configuration {
            Configuration(completedAt: completedAt)
        }
    }

    private var configuration: Configuration
    private(set) var requests: [(clientID: UUID, expectedSpiritVersion: Int)] = []

    init(configuration: Configuration = .success()) {
        self.configuration = configuration
    }

    func setConfiguration(_ configuration: Configuration) {
        self.configuration = configuration
    }

    func recordedRequests() -> [(clientID: UUID, expectedSpiritVersion: Int)] {
        requests
    }

    func completeOnboarding(
        clientID: UUID,
        expectedSpiritVersion: Int
    ) async throws -> OnboardingCompleteResult {
        if let delay = configuration.delay {
            try await Task.sleep(for: delay)
        }

        try Task.checkCancellation()
        requests.append((clientID, expectedSpiritVersion))

        if let error = configuration.error {
            throw error
        }

        return OnboardingCompleteResult(
            onboarding: OnboardingState(
                required: false,
                step: OnboardingConversationDefaults.totalSteps,
                totalSteps: OnboardingConversationDefaults.totalSteps,
                completedAt: configuration.completedAt
            ),
            room: Self.defaultRoom(updatedAt: configuration.completedAt),
            snapshotVersion: expectedSpiritVersion + 1
        )
    }

    private static func defaultRoom(updatedAt: Date) -> RoomSnapshot {
        RoomSnapshot(
            weather: "clear",
            layers: [RoomLayer(key: "floor", variant: "default")],
            letter: nil,
            pendingSightID: nil,
            unreadFootprintCount: 0,
            updatedAt: updatedAt
        )
    }
}
