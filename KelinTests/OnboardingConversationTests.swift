import SwiftData
import XCTest
@testable import Kelin

@MainActor
final class OnboardingConversationTests: XCTestCase {
    func testSuccessfulSendAppendsPairAndAdvancesDisplayStep() async throws {
        let chat = MockOnboardingChatService()
        let (appState, _) = try await makeAppStateAtConversation(chat: chat)

        await appState.sendOnboardingMessage(content: "嗯，我喜欢下雨。")

        XCTAssertEqual(appState.onboardingMessages.count, 2)
        XCTAssertEqual(appState.onboardingMessages[0].role, .user)
        XCTAssertEqual(appState.onboardingMessages[1].role, .spirit)
        XCTAssertEqual(appState.sessionStore.snapshot?.onboarding.step, 1)
        XCTAssertEqual(appState.phase, .needsFirstConversation(step: 2))
        XCTAssertTrue(appState.onboardingChatServiceUsesStub)
    }

    func testFailureDoesNotAdvanceProgress() async throws {
        let chat = MockOnboardingChatService(configuration: .init(error: .networkUnavailable))
        let (appState, _) = try await makeAppStateAtConversation(chat: chat)

        await appState.sendOnboardingMessage(content: "第一句")

        XCTAssertEqual(appState.onboardingMessages.count, 0)
        XCTAssertEqual(appState.sessionStore.snapshot?.onboarding.step, 0)
        XCTAssertEqual(appState.phase, .needsFirstConversation(step: 1))
        XCTAssertEqual(appState.onboardingChatError, .networkUnavailable)
    }

    func testRetryReusesStableClientMessageID() async throws {
        let chat = MockOnboardingChatService(configuration: .init(error: .networkUnavailable))
        let (appState, _) = try await makeAppStateAtConversation(chat: chat)

        await appState.sendOnboardingMessage(content: "重试句")
        let failedRequests = await chat.recordedRequests()
        let clientID = try XCTUnwrap(failedRequests.first?.clientMessageID)

        await chat.setConfiguration(.success)
        appState.clearOnboardingChatError()
        await appState.sendOnboardingMessage(content: "重试句")

        let allRequests = await chat.recordedRequests()
        XCTAssertEqual(allRequests.count, 2)
        XCTAssertEqual(allRequests[0].clientMessageID, clientID)
        XCTAssertEqual(allRequests[1].clientMessageID, clientID)
        XCTAssertEqual(appState.onboardingMessages.count, 2)
    }

    func testRetryOnboardingChatUsesPendingContentWhenDraftIsEmpty() async throws {
        let chat = MockOnboardingChatService(configuration: .init(error: .timedOut))
        let (appState, _) = try await makeAppStateAtConversation(chat: chat)

        await appState.sendOnboardingMessage(content: "超时句")
        XCTAssertEqual(appState.onboardingChatError, .timedOut)
        XCTAssertEqual(appState.lastOnboardingDraft, "超时句")
        let clientID = try XCTUnwrap(await chat.recordedRequests().first?.clientMessageID)

        await chat.setConfiguration(.success)
        await appState.retryOnboardingChat()

        let allRequests = await chat.recordedRequests()
        XCTAssertEqual(allRequests.count, 2)
        XCTAssertEqual(allRequests[1].content, "超时句")
        XCTAssertEqual(allRequests[1].clientMessageID, clientID)
        XCTAssertNil(appState.onboardingChatError)
        XCTAssertEqual(appState.onboardingMessages.count, 2)
    }

    func testConcurrentSendIsSingleFlight() async throws {
        let chat = MockOnboardingChatService(configuration: .init(delay: .milliseconds(100)))
        let (appState, _) = try await makeAppStateAtConversation(chat: chat)

        async let first: Void = appState.sendOnboardingMessage(content: "一")
        async let second: Void = appState.sendOnboardingMessage(content: "二")
        _ = await (first, second)

        let requests = await chat.recordedRequests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(appState.onboardingMessages.filter { $0.role == .user }.count, 1)
    }

    func testFiveSuccessfulRoundsCompleteConversation() async throws {
        let complete = MockOnboardingCompleteService()
        let (appState, _) = try await makeAppStateAtConversation(
            chat: MockOnboardingChatService(),
            complete: complete
        )

        for index in 1 ... 5 {
            await appState.sendOnboardingMessage(content: "第\(index)句")
        }

        await waitForPhase(.ready, in: appState, timeout: .seconds(3))

        XCTAssertEqual(appState.sessionStore.snapshot?.onboarding.step, 5)
        XCTAssertNotNil(appState.sessionStore.snapshot?.onboarding.completedAt)
        XCTAssertEqual(appState.onboardingMessages.filter { $0.role == .user }.count, 5)

        await appState.sendOnboardingMessage(content: "第六句不应发送")
        XCTAssertEqual(appState.onboardingMessages.filter { $0.role == .user }.count, 5)
    }

    func testEmptyMessageIsIgnored() async throws {
        let chat = MockOnboardingChatService()
        let (appState, _) = try await makeAppStateAtConversation(chat: chat)

        await appState.sendOnboardingMessage(content: "   ")

        let requests = await chat.recordedRequests()
        XCTAssertTrue(requests.isEmpty)
    }

    func testOnboardingConversationViewCanBeConstructed() async throws {
        let (appState, _) = try await makeAppStateAtConversation()
        _ = OnboardingConversationView(appState: appState, displayStep: 1)
    }

    private func makeAppStateAtConversation(
        chat: MockOnboardingChatService = MockOnboardingChatService(),
        complete: MockOnboardingCompleteService = MockOnboardingCompleteService()
    ) async throws -> (appState: AppState, chat: MockOnboardingChatService) {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let appState = AppState(
            auth: MockAuthService(),
            localStore: LocalStore(modelContainer: container),
            bootstrapService: MockBootstrapService(mode: .newUser),
            hatchService: MockHatchService(),
            onboardingChatService: chat,
            onboardingCompleteService: complete,
            hatchAnimationDuration: .zero
        )

        appState.beginLaunch()
        await waitForPhase(.needsAgreement, in: appState)
        await appState.submitAgreement(
            aiDisclosureAccepted: true,
            hasViewedUserTerms: true,
            hasViewedDataNotice: true
        )
        await appState.createSpirit(selectedOption: .variable)
        XCTAssertEqual(appState.phase, .needsFirstConversation(step: 1))

        return (appState, chat)
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
