import Foundation

struct PactQuestion: Equatable, Sendable, Identifiable {
    let id: String
    let text: String
}

struct PactSession: Equatable, Sendable, Identifiable {
    let id: UUID
    let pactID: UUID?
    let date: String
    let explain: String?
    let questions: [PactQuestion]
    let rowVersion: Int
    let status: String?
    let dayIndex: Int?
    let answeredCount: Int?
}

struct PactAnswer: Equatable, Sendable {
    let finalized: Bool
    let score: Int?
    let pactStatus: String?
    let feedbackSummary: String?
    let improvement: String?
    let answeredCount: Int?
    let rowVersion: Int?
}

struct PactMutation: Equatable, Sendable {
    let pact: PactSummary?
    let session: PactSession?
    let answer: PactAnswer?
    let patch: SessionPatch
    let quotas: [QuotaEntry]
    let events: [MutationEvent]
}

struct PactAnswerQueueItem: Equatable, Sendable, Codable, Identifiable {
    let clientID: UUID
    let sessionID: UUID
    let expectedSessionVersion: Int
    let questionID: String
    let text: String
    let order: Int

    var id: UUID { clientID }
}

struct PactQueueState: Equatable, Sendable, Codable {
    var items: [PactAnswerQueueItem]
    var sessionID: UUID?
    var sessionDate: String?
    var sessionStatus: String?
    var rowVersion: Int?
    var dayIndex: Int?
}

enum PactStableIDsDraftID {
    static func make(accountUserID: UUID) -> UUID {
        var bytes = accountUserID.uuid
        bytes.0 = bytes.0 &+ 5
        bytes.1 = ~bytes.1
        bytes.6 = (bytes.6 & 0x0F) | 0x60
        bytes.8 = (bytes.8 & 0x3F) | 0x80
        return UUID(uuid: bytes)
    }
}

enum PactQueueDraftID {
    static func make(accountUserID: UUID) -> UUID {
        var bytes = accountUserID.uuid
        bytes.0 = bytes.0 &+ 6
        bytes.1 = ~bytes.1
        bytes.6 = (bytes.6 & 0x0F) | 0x60
        bytes.8 = (bytes.8 & 0x3F) | 0x80
        return UUID(uuid: bytes)
    }
}
