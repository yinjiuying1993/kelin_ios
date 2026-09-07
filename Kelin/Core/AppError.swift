enum PermissionKind: String, CaseIterable, Equatable, Sendable {
    case microphone
    case photoLibrary
    case location
    case notifications
}

enum QuotaKind: String, CaseIterable, Equatable, Sendable {
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
}
