import SwiftData
import XCTest
@testable import Kelin

final class LocalStoreTests: XCTestCase {
    private var container: ModelContainer!
    private var store: LocalStore!

    private let accountA = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
    private let accountB = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!

    override func setUpWithError() throws {
        container = try KelinModelContainerFactory.makeInMemoryContainer()
        store = LocalStore(modelContainer: container)
    }

    override func tearDownWithError() throws {
        store = nil
        container = nil
    }

    func testAccountIsolationForBootstrap() async throws {
        try await store.upsertBootstrap(
            CachedBootstrapRecord(
                accountUserID: accountA,
                payloadData: Data("a".utf8),
                snapshotVersion: 1,
                updatedAt: Date(timeIntervalSince1970: 100)
            )
        )
        try await store.upsertBootstrap(
            CachedBootstrapRecord(
                accountUserID: accountB,
                payloadData: Data("b".utf8),
                snapshotVersion: 2,
                updatedAt: Date(timeIntervalSince1970: 200)
            )
        )

        let bootstrapA = try await store.fetchBootstrap(accountUserID: accountA)
        let bootstrapB = try await store.fetchBootstrap(accountUserID: accountB)

        XCTAssertEqual(bootstrapA?.payloadData, Data("a".utf8))
        XCTAssertEqual(bootstrapB?.payloadData, Data("b".utf8))
    }

    func testClearAccountRemovesOnlyTargetAccountData() async throws {
        try await store.upsertBootstrap(
            CachedBootstrapRecord(
                accountUserID: accountA,
                payloadData: Data("a".utf8),
                snapshotVersion: 1,
                updatedAt: Date()
            )
        )
        try await store.upsertBootstrap(
            CachedBootstrapRecord(
                accountUserID: accountB,
                payloadData: Data("b".utf8),
                snapshotVersion: 1,
                updatedAt: Date()
            )
        )

        try await store.clearAccount(accountUserID: accountA)

        let clearedBootstrap = try await store.fetchBootstrap(accountUserID: accountA)
        let remainingBootstrap = try await store.fetchBootstrap(accountUserID: accountB)

        XCTAssertNil(clearedBootstrap)
        XCTAssertNotNil(remainingBootstrap)
    }

    func testMessageLimitKeepsQueuedMessagesAndTrimsSentHistory() async throws {
        let queuedID = UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!
        let baseTime = Date(timeIntervalSince1970: 1_700_000_000)

        for index in 0..<55 {
            try await store.upsertMessage(
                CachedMessageRecord(
                    id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012X", index + 1))!,
                    accountUserID: accountA,
                    clientID: UUID(),
                    payloadData: Data("sent-\(index)".utf8),
                    sendState: .sent,
                    createdAt: baseTime.addingTimeInterval(TimeInterval(index))
                )
            )
        }

        try await store.upsertMessage(
            CachedMessageRecord(
                id: queuedID,
                accountUserID: accountA,
                clientID: UUID(),
                payloadData: Data("queued".utf8),
                sendState: .queued,
                createdAt: baseTime.addingTimeInterval(999)
            )
        )

        let messages = try await store.fetchMessages(accountUserID: accountA)
        let queuedMessages = messages.filter { $0.sendState == .queued }
        let sentMessages = messages.filter { $0.sendState == .sent }

        XCTAssertEqual(queuedMessages.count, 1)
        XCTAssertEqual(queuedMessages.first?.id, queuedID)
        XCTAssertEqual(sentMessages.count, LocalStoreLimits.maxSentMessages)
    }

    func testTombstonedMemoryIsHiddenFromActiveFetch() async throws {
        let memoryID = UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")!
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_500)

        try await store.upsertMemory(
            CachedMemoryRecord(
                id: memoryID,
                accountUserID: accountA,
                payloadData: Data("memory".utf8),
                isTombstone: false,
                updatedAt: updatedAt
            )
        )
        try await store.tombstoneMemory(id: memoryID, accountUserID: accountA, updatedAt: updatedAt)

        let activeMemories = try await store.fetchActiveMemories(accountUserID: accountA)
        let tombstonedMemories = try await store.fetchTombstonedMemories(accountUserID: accountA)

        XCTAssertTrue(activeMemories.isEmpty)
        XCTAssertEqual(tombstonedMemories.count, 1)
    }

    func testMemoryLimitRetainsMostRecentActiveRecords() async throws {
        let baseTime = Date(timeIntervalSince1970: 1_700_001_000)

        for index in 0..<(LocalStoreLimits.maxActiveMemories + 5) {
            try await store.upsertMemory(
                CachedMemoryRecord(
                    id: UUID(uuidString: String(format: "00000000-0000-0000-0001-%012X", index + 1))!,
                    accountUserID: accountA,
                    payloadData: Data("memory-\(index)".utf8),
                    isTombstone: false,
                    updatedAt: baseTime.addingTimeInterval(TimeInterval(index))
                )
            )
        }

        let activeMemories = try await store.fetchActiveMemories(accountUserID: accountA)
        XCTAssertEqual(activeMemories.count, LocalStoreLimits.maxActiveMemories)
        XCTAssertEqual(activeMemories.first?.payloadData, Data("memory-104".utf8))
    }

    func testPostcardLimitKeepsUnreadAndTrimsReadHistory() async throws {
        let unreadID = UUID(uuidString: "00000000-0000-0000-0000-0000000000E1")!
        let baseTime = Date(timeIntervalSince1970: 1_700_002_000)

        for index in 0..<35 {
            try await store.upsertPostcard(
                CachedPostcardRecord(
                    id: UUID(uuidString: String(format: "00000000-0000-0000-0002-%012X", index + 1))!,
                    accountUserID: accountA,
                    payloadData: Data("read-\(index)".utf8),
                    isRead: true,
                    createdAt: baseTime.addingTimeInterval(TimeInterval(index))
                )
            )
        }

        try await store.upsertPostcard(
            CachedPostcardRecord(
                id: unreadID,
                accountUserID: accountA,
                payloadData: Data("unread".utf8),
                isRead: false,
                createdAt: baseTime.addingTimeInterval(999)
            )
        )

        let postcards = try await store.fetchPostcards(accountUserID: accountA)
        let unread = postcards.filter { !$0.isRead }
        let read = postcards.filter(\.isRead)

        XCTAssertEqual(unread.count, 1)
        XCTAssertEqual(unread.first?.id, unreadID)
        XCTAssertEqual(read.count, LocalStoreLimits.maxReadPostcards)
    }

    func testPendingOperationPreservesStableClientID() async throws {
        let operationID = UUID(uuidString: "00000000-0000-0000-0000-0000000000F1")!
        let clientID = UUID(uuidString: "00000000-0000-0000-0000-000000000031")!

        try await store.upsertPendingOperation(
            PendingOperationRecord(
                id: operationID,
                accountUserID: accountA,
                kind: .chat,
                clientID: clientID,
                payloadData: Data("payload".utf8),
                createdAt: Date(timeIntervalSince1970: 1_700_003_000),
                attemptCount: 0,
                nextRetryAt: nil,
                lastErrorCode: nil,
                state: .pending
            )
        )

        try await store.upsertPendingOperation(
            PendingOperationRecord(
                id: operationID,
                accountUserID: accountA,
                kind: .chat,
                clientID: clientID,
                payloadData: Data("payload".utf8),
                createdAt: Date(timeIntervalSince1970: 1_700_003_000),
                attemptCount: 1,
                nextRetryAt: Date(timeIntervalSince1970: 1_700_003_100),
                lastErrorCode: "NETWORK_UNAVAILABLE",
                state: .failed
            )
        )

        let pending = try await store.fetchPendingOperations(accountUserID: accountA)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.clientID, clientID)
        XCTAssertEqual(pending.first?.state, .failed)
        XCTAssertEqual(pending.first?.attemptCount, 1)
    }
}
