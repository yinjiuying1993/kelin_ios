import Foundation
@testable import Kelin

actor MockPendingOperationExecutor: PendingOperationExecuting {
    struct Execution: Equatable, Sendable {
        let operationID: UUID
        let clientID: UUID
    }

    private(set) var executions: [Execution] = []
    private var resultsByOperationID: [UUID: PendingOperationExecutionResult] = [:]
    var delay: Duration = .zero

    func setResult(_ result: PendingOperationExecutionResult, for operationID: UUID) {
        resultsByOperationID[operationID] = result
    }

    func setDelay(_ delay: Duration) {
        self.delay = delay
    }

    func execute(_ operation: PendingOperationRecord) async throws -> PendingOperationExecutionResult {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }

        executions.append(
            Execution(operationID: operation.id, clientID: operation.clientID)
        )
        return resultsByOperationID[operation.id] ?? .success
    }
}
