import Foundation

struct CachedBootstrapRecord: Equatable, Sendable {
    let accountUserID: UUID
    let payloadData: Data
    let snapshotVersion: Int
    let updatedAt: Date
}

struct CachedMessageRecord: Equatable, Sendable, Identifiable {
    let id: UUID
    let accountUserID: UUID
    let clientID: UUID
    let payloadData: Data
    let sendState: CachedMessageSendState
    let createdAt: Date
}

struct CachedMemoryRecord: Equatable, Sendable, Identifiable {
    let id: UUID
    let accountUserID: UUID
    let payloadData: Data
    let isTombstone: Bool
    let updatedAt: Date
}

struct CachedPostcardRecord: Equatable, Sendable, Identifiable {
    let id: UUID
    let accountUserID: UUID
    let payloadData: Data
    let isRead: Bool
    let createdAt: Date
}

struct CachedPactRecord: Equatable, Sendable, Identifiable {
    let id: UUID
    let accountUserID: UUID
    let payloadData: Data
    let updatedAt: Date
}

struct DraftRecord: Equatable, Sendable, Identifiable {
    let id: UUID
    let accountUserID: UUID
    let kind: DraftKind
    let payloadData: Data
    let updatedAt: Date
}

struct PendingOperationRecord: Equatable, Sendable, Identifiable {
    let id: UUID
    let accountUserID: UUID
    let kind: PendingOperationKind
    let clientID: UUID
    let payloadData: Data
    let createdAt: Date
    let attemptCount: Int
    let nextRetryAt: Date?
    let lastErrorCode: String?
    let state: PendingOperationState

    func with(
        attemptCount: Int? = nil,
        nextRetryAt: Date?? = nil,
        lastErrorCode: String?? = nil,
        state: PendingOperationState? = nil
    ) -> PendingOperationRecord {
        PendingOperationRecord(
            id: id,
            accountUserID: accountUserID,
            kind: kind,
            clientID: clientID,
            payloadData: payloadData,
            createdAt: createdAt,
            attemptCount: attemptCount ?? self.attemptCount,
            nextRetryAt: nextRetryAt ?? self.nextRetryAt,
            lastErrorCode: lastErrorCode ?? self.lastErrorCode,
            state: state ?? self.state
        )
    }
}
