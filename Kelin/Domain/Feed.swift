import Foundation

struct FeedResource: Equatable, Sendable {
    let id: UUID
    let version: Int
    let kind: String
    let status: String
    let promiseStatus: String?
}

struct MutationEvent: Equatable, Sendable {
    let id: UUID
    let type: String
    let occurredAt: Date
}

struct FeedMutation: Equatable, Sendable {
    let resource: FeedResource
    let patch: SessionPatch
    let quotas: [QuotaEntry]
    let events: [MutationEvent]
    let prop: String?
}

struct SightUploadTicket: Equatable, Sendable {
    let uploadSessionID: UUID
    let method: String
    let url: URL
    let headers: [String: String]
    let objectPath: String
    let expiresAt: Date
    let maxSizeBytes: Int
}

struct ProcessedSightPhoto: Equatable, Sendable {
    let jpeg: Data
    let sha256: String
    let pixelWidth: Int
    let pixelHeight: Int
}
