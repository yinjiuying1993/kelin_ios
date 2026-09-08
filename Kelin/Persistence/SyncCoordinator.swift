import Foundation

actor SyncCoordinator {
    static let defaultDebounceInterval: Duration = .milliseconds(500)

    private let localStore: LocalStore
    private let executor: any PendingOperationExecuting
    private let debounceInterval: Duration

    private var accountUserID: UUID?
    private var replayTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private var isReplaying = false

    init(
        localStore: LocalStore,
        executor: any PendingOperationExecuting,
        debounceInterval: Duration = SyncCoordinator.defaultDebounceInterval
    ) {
        self.localStore = localStore
        self.executor = executor
        self.debounceInterval = debounceInterval
    }

    func setAccountUserID(_ accountUserID: UUID) {
        self.accountUserID = accountUserID
    }

    func enqueue(_ record: PendingOperationRecord) async throws {
        try await localStore.upsertPendingOperation(record)
        scheduleReplay()
    }

    func notifyNetworkRecovered() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                try await Task.sleep(for: self.debounceInterval)
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            await self.scheduleReplayAndWait()
        }
    }

    func resumePendingOperations() async {
        await scheduleReplayAndWait()
    }

    private func scheduleReplay() {
        guard replayTask == nil else {
            return
        }

        replayTask = Task { [weak self] in
            await self?.performReplay()
        }
    }

    private func scheduleReplayAndWait() async {
        if let replayTask {
            await replayTask.value
            return
        }

        await performReplay()
    }

    private func performReplay() async {
        guard !isReplaying else {
            return
        }

        isReplaying = true
        defer {
            isReplaying = false
            replayTask = nil
        }

        guard let accountUserID else {
            return
        }

        do {
            try await normalizeInterruptedOperations(accountUserID: accountUserID)

            while let next = try await nextReplayableOperation(accountUserID: accountUserID) {
                try Task.checkCancellation()

                let inFlight = next.with(state: .inFlight)
                try await localStore.upsertPendingOperation(inFlight)

                let result = try await executor.execute(next)

                switch result {
                case .success:
                    try await localStore.deletePendingOperation(
                        id: next.id,
                        accountUserID: accountUserID
                    )
                case let .retryableFailure(errorCode):
                    let failed = next.with(
                        attemptCount: next.attemptCount + 1,
                        nextRetryAt: .some(Date().addingTimeInterval(1)),
                        lastErrorCode: .some(errorCode),
                        state: .failed
                    )
                    try await localStore.upsertPendingOperation(failed)
                case let .permanentFailure(errorCode):
                    let failed = next.with(
                        lastErrorCode: .some("PERMANENT:\(errorCode)"),
                        state: .failed
                    )
                    try await localStore.upsertPendingOperation(failed)
                }
            }
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }

    private func normalizeInterruptedOperations(accountUserID: UUID) async throws {
        let operations = try await localStore.fetchPendingOperations(accountUserID: accountUserID)

        for operation in operations where operation.state == .inFlight {
            try await localStore.upsertPendingOperation(operation.with(state: .pending))
        }
    }

    private func nextReplayableOperation(accountUserID: UUID) async throws -> PendingOperationRecord? {
        let operations = try await localStore.fetchPendingOperations(accountUserID: accountUserID)
        let now = Date()

        return operations.first { operation in
            switch operation.state {
            case .pending:
                return true
            case .failed:
                guard let lastErrorCode = operation.lastErrorCode else {
                    return false
                }
                guard !lastErrorCode.hasPrefix("PERMANENT:") else {
                    return false
                }
                if let nextRetryAt = operation.nextRetryAt {
                    return nextRetryAt <= now
                }
                return true
            case .inFlight, .succeeded:
                return false
            }
        }
    }
}
