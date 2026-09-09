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
    case visit
    case pact
}

enum AppError: Error, Equatable, Sendable {
    case unauthenticated
    case networkUnavailable
    case timedOut
    case invalidInput
    case permissionDenied(PermissionKind)
    case rateLimited
    case quotaExceeded(QuotaKind)
    case modelUnavailable
    case moderationRejected
    case notFound
    case conflict
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
        case let .permissionDenied(kind):
            "PERMISSION_DENIED_\(kind.rawValue.uppercased())"
        case .rateLimited:
            "RATE_LIMITED"
        case let .quotaExceeded(kind):
            "QUOTA_EXCEEDED_\(kind.rawValue.uppercased())"
        case .modelUnavailable:
            "MODEL_UNAVAILABLE"
        case .moderationRejected:
            "MODERATION_REJECTED"
        case .notFound:
            "NOT_FOUND"
        case .conflict:
            "CONFLICT"
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
