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

    func testRelaunchReusesPersistedChatClientMessageID() async throws {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let localStore = LocalStore(modelContainer: container)
        let auth = MockAuthService()
        let chat = MockOnboardingChatService(configuration: .init(error: .networkUnavailable))

        let firstLaunch = AppState(
            auth: auth,
            localStore: localStore,
            bootstrapService: MockBootstrapService(mode: .newUser),
            hatchService: MockHatchService(),
            onboardingChatService: chat,
            onboardingCompleteService: MockOnboardingCompleteService(),
            hatchAnimationDuration: .zero
        )
        try await bootstrapToConversation(firstLaunch)
        await firstLaunch.sendOnboardingMessage(content: "未完成句")

        XCTAssertEqual(firstLaunch.onboardingChatError, .networkUnavailable)
        let failedRequests = await chat.recordedRequests()
        let failedID = try XCTUnwrap(failedRequests.last?.clientMessageID)

        await chat.setConfiguration(.success)
        let relaunch = AppState(
            auth: auth,
            localStore: localStore,
            bootstrapService: MockBootstrapService(mode: .newUser),
            hatchService: MockHatchService(),
            onboardingChatService: chat,
            onboardingCompleteService: MockOnboardingCompleteService(),
            hatchAnimationDuration: .zero
        )
        relaunch.beginLaunch()
        await waitForPhase(.needsFirstConversation(step: 1), in: relaunch, timeout: .seconds(5))
        await relaunch.sendOnboardingMessage(content: "未完成句")

        let retryRequests = await chat.recordedRequests()
        let retryID = try XCTUnwrap(retryRequests.last?.clientMessageID)
        XCTAssertEqual(retryID, failedID)
        XCTAssertNil(relaunch.onboardingChatError)
        XCTAssertEqual(relaunch.sessionStore.snapshot?.onboarding.step, 1)
    }

    func testCompleteConflictRefreshesHatchedBootstrap() async throws {
        let complete = MockOnboardingCompleteService(configuration: .init(error: AppError.conflict))
        let bootstrap = MockBootstrapService(mode: .newUser)
        let (appState, _) = try await makeAppStateAtConversation(
            complete: complete,
            bootstrap: bootstrap,
            hatchAnimationDuration: .zero
        )

        for index in 1 ... 4 {
            await appState.sendOnboardingMessage(content: "第\(index)句")
        }
        await bootstrap.setMode(.fullUser)
        await appState.sendOnboardingMessage(content: "第5句")

        await waitForPhase(.ready, in: appState, timeout: .seconds(3))
        XCTAssertNil(appState.onboardingCompleteError)
        XCTAssertNotNil(appState.sessionStore.snapshot?.onboarding.completedAt)
    }

    func testChatMapperUsesCloudyWeatherAndSpiritPatch() throws {
        let request = ChatMapper.makeRequest(
            clientMessageID: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
            content: "你好"
        )
        XCTAssertEqual(request.context.weather, "cloudy")
        XCTAssertEqual(request.source, "onboarding")
        XCTAssertTrue(request.onboarding)

        let envelope: APIEnvelope<ChatMutationResultDTO> = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<ChatMutationResultDTO>.self,
            from: Data(Self.chatSuccessEnvelope.utf8)
        )
        let result = try ChatMapper.mapOnboardingChatResult(try XCTUnwrap(envelope.data))
        XCTAssertEqual(result.completedRounds, 1)
        XCTAssertEqual(result.spirit?.version, 2)
        XCTAssertTrue(result.usesStubProvider)
    }

    func testOnboardingStableIDsCodecRoundTrip() throws {
        let ids = OnboardingStableIDs(
            spiritClientID: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
            chatClientMessageID: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!,
            chatContent: "未完成句",
            completeClientID: UUID(uuidString: "00000000-0000-0000-0000-000000000023")!
        )

        let decoded = try OnboardingStableIDsCodec.decode(try OnboardingStableIDsCodec.encode(ids))
        XCTAssertEqual(decoded, ids)
        XCTAssertNotEqual(
            OnboardingConversationDraftID.make(accountUserID: ids.spiritClientID!),
            OnboardingStableIDsDraftID.make(accountUserID: ids.spiritClientID!)
        )
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
        bootstrap: MockBootstrapService = MockBootstrapService(mode: .newUser),
        hatchAnimationDuration: Duration = .zero
    ) async throws -> (appState: AppState, complete: MockOnboardingCompleteService) {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let appState = AppState(
            auth: MockAuthService(),
            localStore: LocalStore(modelContainer: container),
            bootstrapService: bootstrap,
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

    private static let chatSuccessEnvelope = """
    {
      "ok": true,
      "data": {
        "resource": {
          "type": "chat_turn",
          "onboarding": true,
          "generation_source": "stub",
          "user_message": {
            "id": "00000000-0000-0000-0000-000000000031",
            "content": "你好"
          },
          "spirit_message": {
            "id": "00000000-0000-0000-0000-000000000032",
            "content": "嗯。"
          },
          "conversation_window_id": "00000000-0000-0000-0000-000000000041",
          "should_extract": false,
          "usage": { "input_units": 0, "output_units": 0 }
        },
        "patch": {
          "snapshot_version": 2,
          "spirit": {
            "id": "00000000-0000-0000-0000-000000000101",
            "user_id": "00000000-0000-0000-0000-0000000000A1",
            "name": "未名",
            "egg": "warm",
            "invite_code": "ABCD2345",
            "closeness": 65,
            "curiosity": 55,
            "sharpness": 35,
            "nocturnal": 40,
            "stubborn": 40,
            "hunger": 80,
            "energy": 80,
            "mood": 60,
            "bond": 0,
            "stage": "whelp",
            "status": "home",
            "scholar_marks": [],
            "version": 2,
            "away_until": null,
            "study_until": null,
            "last_interact_at": "2026-09-07T03:46:00Z",
            "created_at": "2026-09-07T03:46:00Z",
            "updated_at": "2026-09-07T03:46:00Z",
            "hatched_at": null
          },
          "room": null,
          "onboarding": {
            "required": true,
            "step": 1,
            "total_steps": 5,
            "completed_at": null
          }
        }
      },
      "error": null,
      "request_id": "req-chat-success",
      "server_time": "2026-09-07T03:46:00Z"
    }
    """

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
