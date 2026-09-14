import Foundation

enum PermissionKind: String, CaseIterable, Equatable, Sendable {
    case microphone
    case photoLibrary
    case location
    case notifications
}

enum QuotaKind: String, CaseIterable, Equatable, Sendable, Codable {
    case chat
    case asr
    case tts
    case sight
    case search
    case visit
    case pact
    case food
    case knowledge
    case emotion
}

enum AppError: Error, Equatable, Sendable {
    case unauthenticated
    case networkUnavailable
    case timedOut
    case invalidInput
    case invalidCursor
    case permissionDenied(PermissionKind)
    case rateLimited
    case quotaExceeded(QuotaKind, resetAt: Date?)
    case asrEmptyResult
    case modelUnavailable
    case moderationRejected
    case notFound
    case conflict
    case selfFriendNotAllowed
    case accountDeletePending
    case reportLineUnavailable
    case spiritNotLost
    case recallSourceInvalid
    case sightUploadUnavailable
    case idempotencyConflict
    case idempotencyInProgress
    case decoding
    case cancelled
    case unknown(requestID: String)

    var diagnosticCode: String {
        switch self {
        case .unauthenticated:
            "UNAUTHENTICATED"
        case .networkUnavailable:
            "NETWORK_UNAVAILABLE"
        case .timedOut:
            "TIMED_OUT"
        case .invalidInput:
            "INVALID_INPUT"
        case .invalidCursor:
            "INVALID_CURSOR"
        case let .permissionDenied(kind):
            "PERMISSION_DENIED_\(kind.rawValue.uppercased())"
        case .rateLimited:
            "RATE_LIMITED"
        case let .quotaExceeded(kind, _):
            "QUOTA_EXCEEDED_\(kind.rawValue.uppercased())"
        case .asrEmptyResult:
            "ASR_EMPTY_RESULT"
        case .modelUnavailable:
            "MODEL_UNAVAILABLE"
        case .moderationRejected:
            "MODERATION_REJECTED"
        case .notFound:
            "NOT_FOUND"
        case .conflict:
            "CONFLICT"
        case .selfFriendNotAllowed:
            "SELF_FRIEND_NOT_ALLOWED"
        case .accountDeletePending:
            "ACCOUNT_DELETE_PENDING"
        case .reportLineUnavailable:
            "REPORT_LINE_UNAVAILABLE"
        case .spiritNotLost:
            "SPIRIT_NOT_LOST"
        case .recallSourceInvalid:
            "RECALL_SOURCE_INVALID"
        case .sightUploadUnavailable:
            "SIGHT_UPLOAD_UNAVAILABLE"
        case .idempotencyConflict:
            "IDEMPOTENCY_CONFLICT"
        case .idempotencyInProgress:
            "IDEMPOTENCY_IN_PROGRESS"
        case .decoding:
            "DECODING"
        case .cancelled:
            "CANCELLED"
        case .unknown:
            "UNKNOWN"
        }
    }

    var diagnosticRequestID: String? {
        if case let .unknown(requestID) = self, !requestID.isEmpty {
            return requestID
        }
        return nil
    }
}
