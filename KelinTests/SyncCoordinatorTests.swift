import SwiftData
import XCTest
@testable import Kelin

final class SyncCoordinatorTests: XCTestCase {
    private var container: ModelContainer!
    private var localStore: LocalStore!
    private var executor: MockPendingOperationExecutor!
    private var coordinator: SyncCoordinator!

    private let accountUserID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!

    override func setUp() async throws {
        container = try KelinModelContainerFactory.makeInMemoryContainer()
        localStore = LocalStore(modelContainer: container)
        executor = MockPendingOperationExecutor()
        coordinator = SyncCoordinator(
            localStore: localStore,
            executor: executor,
            debounceInterval: .milliseconds(50)
        )
        await coordinator.setAccountUserID(accountUserID)
    }

    override func tearDown() async throws {
        coordinator = nil
        executor = nil
        localStore = nil
        container = nil
    }

    func testReplayProcessesPendingOperationsInFIFOOrder() async throws {
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let thirdID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let baseTime = Date(timeIntervalSince1970: 1_700_010_000)

        try await coordinator.enqueue(makePending(id: firstID, clientID: UUID(), createdAt: baseTime))
        try await coordinator.enqueue(
            makePending(
                id: secondID,
                clientID: UUID(),
                createdAt: baseTime.addingTimeInterval(1)
            )
        )
        try await coordinator.enqueue(
            makePending(
                id: thirdID,
                clientID: UUID(),
                createdAt: baseTime.addingTimeInterval(2)
            )
        )

        await coordinator.resumePendingOperations()

        let executions = await executor.executions
        XCTAssertEqual(executions.map(\.operationID), [firstID, secondID, thirdID])
        let pending = try await localStore.fetchPendingOperations(accountUserID: accountUserID)
        XCTAssertTrue(pending.isEmpty)
    }

    func testRetryPreservesStableClientID() async throws {
        let operationID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        let clientID = UUID(uuidString: "00000000-0000-0000-0000-000000000031")!

        await executor.setResult(.retryableFailure(errorCode: "NETWORK_UNAVAILABLE"), for: operationID)
        try await coordinator.enqueue(makePending(id: operationID, clientID: clientID))

        await coordinator.resumePendingOperations()

        var stored = try await localStore.fetchPendingOperations(accountUserID: accountUserID)
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.clientID, clientID)
        XCTAssertEqual(stored.first?.state, .failed)

        let retryable = try XCTUnwrap(stored.first).with(nextRetryAt: .some(Date(timeIntervalSince1970: 0)))
        try await localStore.upsertPendingOperation(retryable)

        await executor.setResult(.success, for: operationID)
        await coordinator.resumePendingOperations()

        stored = try await localStore.fetchPendingOperations(accountUserID: accountUserID)
        XCTAssertTrue(stored.isEmpty)

        let executions = await executor.executions
        XCTAssertEqual(executions.map(\.clientID), [clientID, clientID])
    }

    func testSingleFlightReplayDoesNotRunConcurrentExecutions() async throws {
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!

        await executor.setResult(.success, for: firstID)
        await executor.setResult(.success, for: secondID)
        await executor.setDelay(.milliseconds(100))

        try await coordinator.enqueue(makePending(id: firstID, clientID: UUID()))
        try await coordinator.enqueue(makePending(id: secondID, clientID: UUID()))

        let syncCoordinator = coordinator
        async let firstReplay: Void = syncCoordinator!.resumePendingOperations()
        async let secondReplay: Void = syncCoordinator!.resumePendingOperations()
        _ = await (firstReplay, secondReplay)

        let executions = await executor.executions
        XCTAssertEqual(executions.count, 2)
        XCTAssertEqual(executions.map(\.operationID), [firstID, secondID])
    }

    func testNetworkRecoveryDebounceCoalescesReplay() async throws {
        let operationID = UUID(uuidString: "00000000-0000-0000-0000-000000000007")!

        try await coordinator.enqueue(makePending(id: operationID, clientID: UUID()))

        await coordinator.notifyNetworkRecovered()
        await coordinator.notifyNetworkRecovered()
        await coordinator.notifyNetworkRecovered()

        try await Task.sleep(for: .milliseconds(120))

        let executions = await executor.executions
        XCTAssertEqual(executions.count, 1)
        XCTAssertEqual(executions.first?.operationID, operationID)
    }

    func testPermanentFailureKeepsPendingOperationForManualRetry() async throws {
        let operationID = UUID(uuidString: "00000000-0000-0000-0000-000000000008")!
        let clientID = UUID(uuidString: "00000000-0000-0000-0000-000000000041")!

        await executor.setResult(.permanentFailure(errorCode: "INVALID_INPUT"), for: operationID)
        try await coordinator.enqueue(makePending(id: operationID, clientID: clientID))

        await coordinator.resumePendingOperations()
        await coordinator.resumePendingOperations()

        let stored = try await localStore.fetchPendingOperations(accountUserID: accountUserID)
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.clientID, clientID)
        XCTAssertEqual(stored.first?.lastErrorCode, "PERMANENT:INVALID_INPUT")

        let executions = await executor.executions
        XCTAssertEqual(executions.count, 1)
    }

    func testRestartRecoveryResumesInterruptedInFlightOperation() async throws {
        let operationID = UUID(uuidString: "00000000-0000-0000-0000-000000000009")!
        let clientID = UUID(uuidString: "00000000-0000-0000-0000-000000000051")!

        try await localStore.upsertPendingOperation(
            makePending(id: operationID, clientID: clientID).with(state: .inFlight)
        )

        await coordinator.resumePendingOperations()

        let stored = try await localStore.fetchPendingOperations(accountUserID: accountUserID)
        XCTAssertTrue(stored.isEmpty)

        let executions = await executor.executions
        XCTAssertEqual(executions.map(\.clientID), [clientID])
    }

    private func makePending(
        id: UUID,
        clientID: UUID,
        createdAt: Date = Date(timeIntervalSince1970: 1_700_010_000)
    ) -> PendingOperationRecord {
        PendingOperationRecord(
            id: id,
            accountUserID: accountUserID,
            kind: .chat,
            clientID: clientID,
            payloadData: Data("payload".utf8),
            createdAt: createdAt,
            attemptCount: 0,
            nextRetryAt: nil,
            lastErrorCode: nil,
            state: .pending
        )
    }
}
