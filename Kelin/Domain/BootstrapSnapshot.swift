import Foundation

struct RoomLayer: Equatable, Sendable, Codable {
    let key: String
    let variant: String
}

struct RoomSnapshot: Equatable, Sendable, Codable {
    let weather: String
    let layers: [RoomLayer]
    let letter: String?
    let pendingSightID: UUID?
    let unreadFootprintCount: Int
    let updatedAt: Date
}

enum ReportStatus: String, Sendable, CaseIterable, Codable {
    case locked
    case generating
    case partial
    case ready
    case failed
}

struct ReportEligibility: Equatable, Sendable, Codable {
    let isEligible: Bool
    let eligibleAt: Date
    let daysRemaining: Int
    let requiredDialogueRounds: Int
    let completedDialogueRounds: Int
    let dialogueRoundsRemaining: Int
}

struct ReportSnapshot: Equatable, Sendable, Codable {
    let status: ReportStatus
    let reportID: UUID?
    let eligibility: ReportEligibility
    let card: ReportCard?

    init(
        status: ReportStatus,
        reportID: UUID?,
        eligibility: ReportEligibility,
        card: ReportCard? = nil
    ) {
        self.status = status
        self.reportID = reportID
        self.eligibility = eligibility
        self.card = card
    }
}

struct QuotaEntry: Equatable, Sendable, Codable {
    let capability: QuotaKind
    let used: Int
    let limit: Int
    let resetAt: Date
}

struct FeatureFlags: Equatable, Sendable, Codable {
    let remoteSearch: Bool
    let imageFeed: Bool
}

struct MemorySummary: Equatable, Sendable, Identifiable, Codable {
    let id: UUID
    let type: String
    let summary: String
    let status: String
    let createdAt: Date
    let version: Int
    let tags: [String]
    let salience: Int
    let confidence: Double

    init(
        id: UUID,
        type: String,
        summary: String,
        status: String,
        createdAt: Date,
        version: Int = 1,
        tags: [String] = [],
        salience: Int = 0,
        confidence: Double = 0
    ) {
        self.id = id
        self.type = type
        self.summary = summary
        self.status = status
        self.createdAt = createdAt
        self.version = version
        self.tags = tags
        self.salience = salience
        self.confidence = confidence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        summary = try container.decode(String.self, forKey: .summary)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        salience = try container.decodeIfPresent(Int.self, forKey: .salience) ?? 0
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
    }
}

struct MemoryTombstone: Equatable, Sendable, Identifiable, Codable {
    let id: UUID
    let deletedAt: Date
}

struct MemoryPage: Equatable, Sendable {
    let items: [MemorySummary]
    let tombstones: [MemoryTombstone]
    let nextCursor: String?
    let hasMore: Bool
    let snapshotAt: Date
}

struct MemoryMutation: Equatable, Sendable {
    let resourceType: String
    let resourceID: UUID
    let resourceStatus: String?
    let patch: SessionPatch
}

struct PostcardSummary: Equatable, Sendable, Identifiable, Codable {
    let id: UUID
    let text: String
    let createdAt: Date
}

struct PactSummary: Equatable, Sendable, Identifiable, Codable {
    let id: UUID
    let theme: String
    let title: String
    let status: String
    let questionBankVersion: String?
    let completedSessions: Int?
    let skippedSessions: Int?
    let completeness: Int?
    let scholarMark: String?

    init(
        id: UUID,
        theme: String,
        title: String,
        status: String,
        questionBankVersion: String? = nil,
        completedSessions: Int? = nil,
        skippedSessions: Int? = nil,
        completeness: Int? = nil,
        scholarMark: String? = nil
    ) {
        self.id = id
        self.theme = theme
        self.title = title
        self.status = status
        self.questionBankVersion = questionBankVersion
        self.completedSessions = completedSessions
        self.skippedSessions = skippedSessions
        self.completeness = completeness
        self.scholarMark = scholarMark
    }
}

struct BootstrapSnapshot: Equatable, Sendable, Codable {
    let schemaVersion: Int
    let snapshotVersion: Int
    let apiVersion: String
    let spirit: Spirit?
    let room: RoomSnapshot?
    let onboarding: OnboardingState
    let latestMemories: [MemorySummary]
    let unreadPostcards: [PostcardSummary]
    let activePact: PactSummary?
    let report: ReportSnapshot
    let quotas: [QuotaEntry]
    let featureFlags: FeatureFlags
    let serverTime: Date
}
