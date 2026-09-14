import Foundation

enum APIErrorMapper {
    static func map(_ payload: APIErrorPayload, requestID: String) -> AppError {
        switch payload.code {
        case "UNAUTHENTICATED":
            return .unauthenticated
        case "INVALID_INPUT", "DOMAIN_INVALID":
            return .invalidInput
        case "INVALID_CURSOR":
            return .invalidCursor
        case "NOT_FOUND":
            return .notFound
        case "IDEMPOTENCY_IN_PROGRESS":
            return .idempotencyInProgress
        case "SELF_FRIEND_NOT_ALLOWED":
            return .selfFriendNotAllowed
        case "ACCOUNT_DELETE_PENDING":
            return .accountDeletePending
        case "REPORT_LINE_UNAVAILABLE":
            return .reportLineUnavailable
        case "SPIRIT_NOT_LOST":
            return .spiritNotLost
        case "RECALL_SOURCE_INVALID":
            return .recallSourceInvalid
        case "IDEMPOTENCY_CONFLICT":
            return .idempotencyConflict
        case "CONFLICT", "MEMORY_NOT_ACTIVE",
             "PROMISE_NOT_ACTIVE", "UPLOAD_NOT_READY",
             "PACT_ALREADY_ACTIVE", "PACT_DAY_CLOSED", "PACT_QUESTION_ALREADY_ANSWERED",
             "PACT_SESSION_ALREADY_SUBMITTED",
             "ONBOARDING_INCOMPLETE", "ONBOARDING_ALREADY_COMPLETED":
            return .conflict
        case "PACT_QUESTION_NOT_FOUND":
            return .notFound
        case "UPLOAD_EXPIRED":
            return .timedOut
        case "RATE_LIMITED":
            return .rateLimited
        case "QUOTA_EXCEEDED":
            if let quota = payload.details?["quota"], let kind = QuotaKind(rawValue: quota) {
                let resetAt = payload.details?["reset_at"].flatMap(APIDecoding.parseDate)
                return .quotaExceeded(kind, resetAt: resetAt)
            }
            return .unknown(requestID: requestID)
        case "ASR_EMPTY_RESULT":
            return .asrEmptyResult
        case "MODEL_UNAVAILABLE":
            return .modelUnavailable
        case "DEPENDENCY_UNAVAILABLE":
            return .networkUnavailable
        case "PROVIDER_TIMEOUT":
            return .timedOut
        case "MODERATION_REJECTED":
            return .moderationRejected
        default:
            return .unknown(requestID: requestID)
        }
    }
}
