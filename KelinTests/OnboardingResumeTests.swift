import SwiftData
import XCTest
@testable import Kelin

@MainActor
final class OnboardingResumeTests: XCTestCase {
    func testRelaunchRestoresStepAndMessagesAfterTwoRounds() async throws {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let localStore = LocalStore(modelContainer: container)
        let auth = MockAuthService()
        let bootstrap = MockBootstrapService(mode: .newUser)
        let chat = MockOnboardingChatService()

        let firstLaunch = AppState(
            auth: auth,
            localStore: localStore,
            bootstrapService: bootstrap,
            hatchService: MockHatchService(),
            onboardingChatService: chat,
            onboardingCompleteService: MockOnboardingCompleteService(),
            hatchAnimationDuration: .zero
        )

        try await bootstrapToConversation(firstLaunch)
        await firstLaunch.sendOnboardingMessage(content: "第一句")
        await firstLaunch.sendOnboardingMessage(content: "第二句")

        XCTAssertEqual(firstLaunch.onboardingMessages.count, 4)
        XCTAssertEqual(firstLaunch.sessionStore.snapshot?.onboarding.step, 2)

        let session = try await auth.restoreSession()
        let userID = try XCTUnwrap(session?.userID)
        let drafts = try await localStore.fetchDrafts(accountUserID: userID)
        XCTAssertEqual(
            drafts.filter { $0.kind == .onboardingConversation }.count,
            1,
            "onboarding messages should be persisted before relaunch"
        )

        let relaunch = AppState(
            auth: auth,
            localStore: localStore,
            bootstrapService: bootstrap,
            hatchService: MockHatchService(),
            onboardingChatService: chat,
            onboardingCompleteService: MockOnboardingCompleteService(),
            hatchAnimationDuration: .zero
        )

        relaunch.beginLaunch()
        await waitForPhase(.needsFirstConversation(step: 3), in: relaunch, timeout: .seconds(5))

        XCTAssertEqual(relaunch.sessionStore.snapshot?.onboarding.step, 2, "bootstrap step should resume from cache")
        XCTAssertEqual(relaunch.onboardingMessages.count, 4, "onboarding messages should restore from draft cache")
        XCTAssertEqual(relaunch.onboardingMessages.filter { $0.role == .user }.count, 2)
    }

    func testFifthMessageTriggersHatchCompleteAndReady() async throws {
        let complete = MockOnboardingCompleteService()
        let (appState, _) = try await makeAppStateAtConversation(
            complete: complete,
            hatchAnimationDuration: .zero
        )

        for index in 1 ... 5 {
            await appState.sendOnboardingMessage(content: "第\(index)句")
        }

        await waitForPhase(.ready, in: appState, timeout: .seconds(3))

        XCTAssertNotNil(appState.sessionStore.snapshot?.onboarding.completedAt)
        XCTAssertFalse(appState.isHatching)
        let requests = await complete.recordedRequests()
        XCTAssertEqual(requests.count, 1)
    }

    func testCompleteUsesStableClientIDAcrossRetries() async throws {
        let complete = MockOnboardingCompleteService(configuration: .init(error: AppError.networkUnavailable))
        let (appState, _) = try await makeAppStateAtConversation(
            complete: complete,
            hatchAnimationDuration: .zero
        )

        for index in 1 ... 5 {
            await appState.sendOnboardingMessage(content: "第\(index)句")
        }

        await waitForOnboardingCompleteFailure(in: appState, complete: complete)
        XCTAssertEqual(appState.onboardingCompleteError, AppError.networkUnavailable)
        XCTAssertEqual(appState.phase, .needsFirstConversation(step: 5))

        let failedRequests = await complete.recordedRequests()
        XCTAssertEqual(failedRequests.count, 1)

        await complete.setConfiguration(MockOnboardingCompleteService.Configuration.success())
        appState.clearOnboardingCompleteError()
        appState.retryOnboardingComplete()
        await waitForPhase(.ready, in: appState, timeout: .seconds(3))

        let requests = await complete.recordedRequests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].clientID, requests[1].clientID)
    }

    func testOnboardingConversationCodecRoundTrip() throws {
        let messages = [
            OnboardingMessage(role: .user, text: "你好"),
            OnboardingMessage(role: .spirit, text: "嗯")
        ]

        let data = try OnboardingConversationCodec.encode(messages)
        let decoded = try OnboardingConversationCodec.decode(data)

        XCTAssertEqual(decoded, messages)
    }

    private func makeAppStateAtConversation(
        complete: MockOnboardingCompleteService = MockOnboardingCompleteService(),
        hatchAnimationDuration: Duration = .zero
    ) async throws -> (appState: AppState, complete: MockOnboardingCompleteService) {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let appState = AppState(
            auth: MockAuthService(),
            localStore: LocalStore(modelContainer: container),
            bootstrapService: MockBootstrapService(mode: .newUser),
            hatchService: MockHatchService(),
            onboardingChatService: MockOnboardingChatService(),
            onboardingCompleteService: complete,
            hatchAnimationDuration: hatchAnimationDuration
        )

        try await bootstrapToConversation(appState)
        return (appState, complete)
    }

    private func bootstrapToConversation(_ appState: AppState) async throws {
        appState.beginLaunch()
        await waitForPhase(.needsAgreement, in: appState)
        await appState.submitAgreement(
            aiDisclosureAccepted: true,
            hasViewedUserTerms: true,
            hasViewedDataNotice: true
        )
        await appState.createSpirit(selectedOption: .variable)
        XCTAssertEqual(appState.phase, .needsFirstConversation(step: 1))
    }

    private func waitForOnboardingCompleteFailure(
        in appState: AppState,
        complete: MockOnboardingCompleteService,
        minimumRequests: Int = 1,
        timeout: Duration = .seconds(3)
    ) async {
        let deadline = ContinuousClock.now + timeout

        while ContinuousClock.now < deadline {
            let requests = await complete.recordedRequests()
            if appState.onboardingCompleteError != nil, requests.count >= minimumRequests {
                return
            }
            if appState.phase == .ready {
                return
            }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }

        XCTFail("Timed out waiting for onboarding complete failure")
    }

    private func waitForPhase(
        _ expected: AppPhase,
        in appState: AppState,
        timeout: Duration = .seconds(2)
    ) async {
        let deadline = ContinuousClock.now + timeout

        while ContinuousClock.now < deadline {
            if appState.phase == expected {
                return
            }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }

        XCTFail("Expected phase \(expected), got \(appState.phase)")
    }
}
