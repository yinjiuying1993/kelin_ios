import Foundation

struct PublicSpiritProfile: Equatable, Sendable, Identifiable, Codable {
    let id: UUID
    let title: String
    let stage: SpiritStage
    let publicMarks: [String]
    let status: SpiritStatus
}

struct NpcProfile: Equatable, Sendable, Identifiable, Codable {
    var id: String { npcID }
    let npcID: String
    let title: String
    let publicMarks: [String]
}

struct Friend: Equatable, Sendable, Identifiable, Codable {
    var id: UUID { friendID }
    let friendID: UUID
    let spirit: PublicSpiritProfile
    let createdAt: Date
}

struct VisitContext: Equatable, Sendable, Codable {
    let title: String
    let stage: SpiritStage
    let weather: String
    let publicMarks: [String]
}

struct Visit: Equatable, Sendable, Identifiable, Codable {
    let id: UUID
    let planID: UUID
    let destinationIndex: Int
    let status: String
    let host: PublicSpiritProfile?
    let npc: NpcProfile?
    let publicContext: VisitContext
}

struct Postcard: Equatable, Sendable, Identifiable, Codable {
    let id: UUID
    let visitID: UUID
    let sender: PublicSpiritProfile?
    let npc: NpcProfile?
    let text: String
    let readAt: Date?
    let createdAt: Date
    let visit: Visit

    var isUnread: Bool { readAt == nil }

    var senderTitle: String {
        sender?.title ?? npc?.title ?? ""
    }
}

struct SocialPage<Item: Equatable & Sendable>: Equatable, Sendable {
    let items: [Item]
    let nextCursor: String?
    let hasMore: Bool
    let snapshotAt: Date
}

struct SocialPatchSnapshot: Equatable, Sendable {
    let friendsUpsert: [Friend]
    let friendsRemoved: [UUID]
}

struct SocialMutation: Equatable, Sendable {
    let patch: SessionPatch
}
