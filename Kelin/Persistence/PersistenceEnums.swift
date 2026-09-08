import Foundation

enum PendingOperationKind: String, Codable, CaseIterable, Sendable {
    case chat
    case feedFood
    case feedEmotion
    case memorySeal
    case memoryDelete
    case pactAnswer
}

enum PendingOperationState: String, Codable, CaseIterable, Sendable {
    case pending
    case inFlight
    case failed
    case succeeded
}

enum DraftKind: String, Codable, CaseIterable, Sendable {
    case chat
    case knowledge
    case emotion
    case promise
    case sight
}

enum CachedMessageSendState: String, Codable, CaseIterable, Sendable {
    case queued
    case sent
    case failed
}
