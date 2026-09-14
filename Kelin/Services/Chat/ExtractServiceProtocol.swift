import Foundation

enum ExtractStatus: String, Equatable, Sendable {
    case processing
    case extracted
}

struct ExtractResult: Equatable, Sendable {
    let status: ExtractStatus
    let memories: [MemorySummary]
    let patch: SessionPatch
}

protocol ExtractServiceProtocol: Sendable {
    func extract(clientID: UUID, conversationWindowID: UUID) async throws -> ExtractResult
}
