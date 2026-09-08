import Foundation

enum PendingOperationExecutionResult: Equatable, Sendable {
    case success
    case retryableFailure(errorCode: String)
    case permanentFailure(errorCode: String)
}

protocol PendingOperationExecuting: Sendable {
    func execute(_ operation: PendingOperationRecord) async throws -> PendingOperationExecutionResult
}
