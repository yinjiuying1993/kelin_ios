import SwiftData
import XCTest
@testable import Kelin

@MainActor
final class ChatSendQueueTests: XCTestCase {
    private var container: ModelContainer!
    private var localStore: LocalStore!
    private var historyCache: ChatHistoryCache!
    private var chatService: MockChatService!
    private var viewModel: ChatViewModel!

    private let accountUserID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
    private let baseTime = Date(timeIntervalSince1970: 1_700_300_000)

    override func setUp() async throws {
        container = try KelinModelContainerFactory.makeInMemoryContainer()
        localStore = LocalStore(modelContainer: container)
        historyCache = ChatHistoryCache(localStore: localStore)
        chatService = MockChatService()
        viewModel = makeViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        chatService = nil
        historyCache = nil
        localStore = nil
        container = nil
    }

    func testFourthSubmissionIsBlockedWhenOneInFlightAndThreeQueued() async throws {
        await chatService.setConfiguration(
            MockChatService.Configuration(delay: .milliseconds(300), snapshotVersion: 1)
        )

        try await viewModel.submit(text: "one")
        try await waitUntil(timeout: 2) { ChatOutboundRules.hasInFlight(messages: self.viewModel.messages) }

        try await viewModel.submit(text: "two")
        try await viewModel.submit(text: "three")
        try await viewModel.submit(text: "four")

        XCTAssertFalse(viewModel.canSubmit)
        do {
            try await viewModel.submit(text: "five")
            XCTFail("Expected queue limit error")
        } catch let error as AppError {
            XCTAssertEqual(error, .invalidInput)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(ChatOutboundRules.queuedUserMessageCount(viewModel.messages), 3)
        XCTAssertTrue(ChatOutboundRules.hasInFlight(messages: viewModel.messages))
    }

    func testRetryReusesStableClientMessageID() async throws {
        await chatService.setConfiguration(
            MockChatService.Configuration(error: .timedOut, snapshotVersion: 1)
        )

        try await viewModel.submit(text: "retry-me")
        try await waitUntil(timeout: 2) {
            self.viewModel.messages.contains { $0.content == "retry-me" && $0.status == .failed }
        }

        let failed = try XCTUnwrap(viewModel.messages.first { $0.content == "retry-me" })
        await chatService.setConfiguration(MockChatService.Configuration(snapshotVersion: 1))

        try await viewModel.retry(clientMessageID: failed.clientID)
        try await waitUntil(timeout: 2) {
            self.viewModel.messages.contains { $0.role == .spirit && $0.content == "stub-reply-1" }
        }

        let requests = await chatService.recordedRequests()
        XCTAssertEqual(requests.map(\.clientMessageID), [failed.clientID, failed.clientID])
        XCTAssertEqual(requests.map(\.content), ["retry-me", "retry-me"])
    }

    func testRestartRestoreReplaysQueuedMessageWithSameClientID() async throws {
        await chatService.setConfiguration(
            MockChatService.Configuration(error: .networkUnavailable, snapshotVersion: 1)
        )

        try await viewModel.submit(text: "restore-me")
        try await waitUntil(timeout: 2) {
            self.viewModel.messages.contains { $0.content == "restore-me" && $0.status == .queued }
        }

        let queued = try XCTUnwrap(viewModel.messages.first { $0.content == "restore-me" })
        let pending = try await localStore.fetchPendingOperations(accountUserID: accountUserID)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.clientID, queued.clientID)

        await chatService.setConfiguration(MockChatService.Configuration(snapshotVersion: 1))
        let relaunch = makeViewModel()
        try await relaunch.restore()

        try await waitUntil(timeout: 2) {
            relaunch.messages.contains { $0.role == .spirit && $0.content == "stub-reply-1" }
        }

        let requests = await chatService.recordedRequests()
        XCTAssertEqual(requests.map(\.clientMessageID), [queued.clientID])
        XCTAssertEqual(relaunch.messages.first { $0.content == "restore-me" }?.status, .accepted)
    }

    func testSendPumpProcessesQueuedMessagesInFIFOOrder() async throws {
        await chatService.setConfiguration(
            MockChatService.Configuration(delay: .milliseconds(150), snapshotVersion: 1)
        )

        try await viewModel.submit(text: "first")
        try await waitUntil(timeout: 2) { ChatOutboundRules.hasInFlight(messages: self.viewModel.messages) }

        try await viewModel.submit(text: "second")
        try await viewModel.submit(text: "third")

        try await waitUntil(timeout: 5) {
            self.viewModel.messages.filter { $0.role == .spirit }.count == 3
        }

        let requests = await chatService.recordedRequests()
        XCTAssertEqual(requests.map(\.content), ["first", "second", "third"])
    }

    func testFailedMessageDoesNotBlockSubsequentQueuedMessages() async throws {
        let failingService = FailingThenSucceedingChatService()

        viewModel = ChatViewModel(
            chatService: failingService,
            historyCache: historyCache,
            localStore: localStore,
            accountUserID: accountUserID,
            now: { self.baseTime }
        )

        try await viewModel.submit(text: "fail")
        try await viewModel.submit(text: "pass")
        try await waitUntil(timeout: 2) {
            self.viewModel.messages.contains { $0.role == .spirit && $0.content == "ok-pass" }
        }

        XCTAssertEqual(viewModel.messages.first { $0.content == "fail" }?.status, .failed)
        XCTAssertEqual(viewModel.messages.first { $0.content == "pass" }?.status, .accepted)
    }

    func testRestoreDoesNotResendWhenStaleQueuedRowSharesClientID() async throws {
        let clientID = UUID(uuidString: "20000000-0000-4000-8000-0000000000AA")!
        let serverID = UUID(uuidString: "10000000-0000-4000-8000-0000000000AA")!
        let createdAt = Date(timeIntervalSince1970: 1_700_300_100)
        let queued = ChatMessage(
            id: clientID,
            clientID: clientID,
            role: .user,
            content: "已经发出去了",
            source: .text,
            status: .queued,
            createdAt: createdAt
        )
        let accepted = ChatMessage(
            id: serverID,
            clientID: clientID,
            role: .user,
            content: "已经发出去了",
            source: .text,
            status: .accepted,
            createdAt: createdAt
        )

        try await localStore.upsertMessage(
            try ChatHistoryRules.makeRecord(queued, accountUserID: accountUserID)
        )
        try await localStore.upsertMessage(
            try ChatHistoryRules.makeRecord(accepted, accountUserID: accountUserID)
        )
        let storedBefore = try await localStore.fetchMessages(accountUserID: accountUserID)
        XCTAssertEqual(storedBefore.count, 2)

        let relaunch = makeViewModel()
        try await relaunch.restore()
        try await Task.sleep(for: .milliseconds(150))

        let requests = await chatService.recordedRequests()
        XCTAssertTrue(requests.isEmpty)
        XCTAssertEqual(relaunch.messages.filter { $0.role == .user }.count, 1)
        XCTAssertEqual(relaunch.messages.first { $0.role == .user }?.status, .accepted)
        XCTAssertEqual(relaunch.messages.first { $0.role == .user }?.id, serverID)

        let storedAfter = try await localStore.fetchMessages(accountUserID: accountUserID)
        XCTAssertFalse(storedAfter.contains { $0.id == clientID && $0.sendState == .queued })
    }

    func testCancelQueuedRemovesMessageAndPendingOperation() async throws {
        await chatService.setConfiguration(
            MockChatService.Configuration(delay: .milliseconds(300), snapshotVersion: 1)
        )

        try await viewModel.submit(text: "stay")
        try await waitUntil(timeout: 2) { ChatOutboundRules.hasInFlight(messages: self.viewModel.messages) }
        try await viewModel.submit(text: "cancel-me")

        let queued = try XCTUnwrap(viewModel.messages.first { $0.content == "cancel-me" })
        let payload = ChatSendPayload(
            messageID: queued.id,
            clientMessageID: queued.clientID,
            content: queued.content,
            context: ChatSendContext.make(weather: nil)
        )
        try await localStore.upsertPendingOperation(
            try ChatOutboundRules.makePendingOperation(
                accountUserID: accountUserID,
                payload: payload,
                createdAt: baseTime
            )
        )

        try await viewModel.cancelQueued(clientMessageID: queued.clientID)

        XCTAssertNil(viewModel.messages.first { $0.content == "cancel-me" })
        let pending = try await localStore.fetchPendingOperations(accountUserID: accountUserID)
        XCTAssertTrue(pending.isEmpty)
    }

    func testComposerModePreservesDraftAndTapHint() {
        viewModel.draftText = "还没发出"
        viewModel.setComposerMode(.voice)
        XCTAssertEqual(viewModel.composerMode, .voice)
        XCTAssertEqual(viewModel.draftText, "还没发出")

        viewModel.handleVoiceTap()
        XCTAssertEqual(viewModel.voicePhase, .idle)
        XCTAssertEqual(viewModel.voiceStatusMessage, "按住说话，松开发送")

        viewModel.setComposerMode(.text)
        XCTAssertEqual(viewModel.composerMode, .text)
        XCTAssertEqual(viewModel.draftText, "还没发出")
        XCTAssertNil(viewModel.voiceStatusMessage)
    }

    func testCancelVoiceProcessingClearsPhaseWithoutMessages() {
        viewModel.setComposerMode(.voice)
        viewModel.cancelVoiceProcessing()
        XCTAssertEqual(viewModel.voicePhase, .idle)
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertNil(viewModel.voiceStatusMessage)
    }

    private func makeViewModel() -> ChatViewModel {
        ChatViewModel(
            chatService: chatService,
            historyCache: historyCache,
            localStore: localStore,
            accountUserID: accountUserID,
            now: { self.baseTime }
        )
    }

    private func waitUntil(
        timeout: TimeInterval = 5,
        _ predicate: @escaping @MainActor () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if predicate() {
                return
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        throw WaitTimeoutError()
    }
}

private struct WaitTimeoutError: Error {}

private actor FailingThenSucceedingChatService: ChatServiceProtocol {
    private var callCount = 0

    func sendMessage(
        clientMessageID: UUID,
        content: String,
        context: ChatSendContext,
        source: ChatMessage.Source
    ) async throws -> ChatTurnResult {
        callCount += 1
        if callCount == 1 {
            throw AppError.timedOut
        }

        let now = Date(timeIntervalSince1970: 1_700_400_000 + TimeInterval(callCount))
        return ChatTurnResult(
            userMessage: ChatMessage(
                id: UUID(),
                clientID: UUID(),
                role: .user,
                content: content,
                source: .text,
                status: .accepted,
                createdAt: now
            ),
            spiritMessage: ChatMessage(
                id: UUID(),
                clientID: UUID(),
                role: .spirit,
                content: "ok-\(content)",
                source: .text,
                status: .generated,
                createdAt: now
            ),
            conversationWindowID: UUID(),
            shouldExtract: false,
            usesStubProvider: true,
            patch: SessionPatch(
                snapshotVersion: callCount,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                serverTime: now
            )
        )
    }
}
