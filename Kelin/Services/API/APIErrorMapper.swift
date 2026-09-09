import Foundation

enum APIErrorMapper {
    static func map(_ payload: APIErrorPayload, requestID: String) -> AppError {
        switch payload.code {
        case "UNAUTHENTICATED":
            return .unauthenticated
        case "INVALID_INPUT", "DOMAIN_INVALID":
            return .invalidInput
        case "NOT_FOUND":
            return .notFound
        case "CONFLICT", "IDEMPOTENCY_IN_PROGRESS", "IDEMPOTENCY_CONFLICT", "PACT_ALREADY_ACTIVE",
             "ONBOARDING_INCOMPLETE", "ONBOARDING_ALREADY_COMPLETED":
            return .conflict
        case "RATE_LIMITED":
            return .rateLimited
        case "QUOTA_EXCEEDED":
            if let quota = payload.details?["quota"], let kind = QuotaKind(rawValue: quota) {
                return .quotaExceeded(kind)
            }
            return .unknown(requestID: requestID)
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
