import Foundation
import SwiftData

@Model
final class PendingOperation {
    @Attribute(.unique) var id: UUID
    var accountUserID: UUID
    var kindRawValue: String
    var clientID: UUID
    var payloadData: Data
    var createdAt: Date
    var attemptCount: Int
    var nextRetryAt: Date?
    var lastErrorCode: String?
    var stateRawValue: String

    var kind: PendingOperationKind {
        get { PendingOperationKind(rawValue: kindRawValue) ?? .chat }
        set { kindRawValue = newValue.rawValue }
    }

    var state: PendingOperationState {
        get { PendingOperationState(rawValue: stateRawValue) ?? .pending }
        set { stateRawValue = newValue.rawValue }
    }

    init(
        id: UUID,
        accountUserID: UUID,
        kind: PendingOperationKind,
        clientID: UUID,
        payloadData: Data,
        createdAt: Date,
        attemptCount: Int,
        nextRetryAt: Date?,
        lastErrorCode: String?,
        state: PendingOperationState
    ) {
        self.id = id
        self.accountUserID = accountUserID
        self.kindRawValue = kind.rawValue
        self.clientID = clientID
        self.payloadData = payloadData
        self.createdAt = createdAt
        self.attemptCount = attemptCount
        self.nextRetryAt = nextRetryAt
        self.lastErrorCode = lastErrorCode
        self.stateRawValue = state.rawValue
    }
}
