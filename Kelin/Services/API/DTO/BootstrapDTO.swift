import Foundation

struct BootstrapDataDTO: Decodable, Sendable, Equatable {
    let schemaVersion: Int
    let snapshotVersion: Int
    let apiVersion: String
    let spirit: SpiritDTO?
    let room: RoomSnapshotDTO?
    let onboarding: OnboardingDTO
    let latestMemories: [MemorySummaryDTO]
    let unreadPostcards: [PostcardSummaryDTO]
    let activePact: PactSummaryDTO?
    let report: ReportSnapshotDTO
    let quotas: [QuotaEntryDTO]
    let featureFlags: FeatureFlagsDTO

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case snapshotVersion = "snapshot_version"
        case apiVersion = "api_version"
        case spirit
        case room
        case onboarding
        case latestMemories = "latest_memories"
        case unreadPostcards = "unread_postcards"
        case activePact = "active_pact"
        case report
        case quotas
        case featureFlags = "feature_flags"
    }
}

struct RoomSnapshotDTO: Decodable, Sendable, Equatable {
    let weather: String
    let layers: [RoomLayerDTO]
    let letter: String?
    let pendingSight: PendingSightDTO?
    let unreadFootprintCount: Int
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case weather
        case layers
        case letter
        case pendingSight = "pending_sight"
        case unreadFootprintCount = "unread_footprint_count"
        case updatedAt = "updated_at"
    }
}

struct RoomLayerDTO: Decodable, Sendable, Equatable {
    let key: String
    let variant: String
}

struct PendingSightDTO: Decodable, Sendable, Equatable {
    let id: UUID
}

struct MemorySummaryDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let type: String
    let summary: String
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case summary
        case status
        case createdAt = "created_at"
    }
}

struct PostcardSummaryDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case createdAt = "created_at"
    }
}

struct PactSummaryDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let theme: String
    let title: String
    let status: String
}

struct ReportSnapshotDTO: Decodable, Sendable, Equatable {
    let status: String
    let reportID: UUID?
    let eligibility: ReportEligibilityDTO
    let card: String?

    enum CodingKeys: String, CodingKey {
        case status
        case reportID = "report_id"
        case eligibility
        case card
    }
}

struct ReportEligibilityDTO: Decodable, Sendable, Equatable {
    let isEligible: Bool
    let eligibleAt: Date
    let daysRemaining: Int
    let requiredDialogueRounds: Int
    let completedDialogueRounds: Int
    let dialogueRoundsRemaining: Int

    enum CodingKeys: String, CodingKey {
        case isEligible = "is_eligible"
        case eligibleAt = "eligible_at"
        case daysRemaining = "days_remaining"
        case requiredDialogueRounds = "required_dialogue_rounds"
        case completedDialogueRounds = "completed_dialogue_rounds"
        case dialogueRoundsRemaining = "dialogue_rounds_remaining"
    }
}

struct QuotaEntryDTO: Decodable, Sendable, Equatable {
    let capability: String
    let used: Int
    let limit: Int
    let resetAt: Date

    enum CodingKeys: String, CodingKey {
        case capability
        case used
        case limit
        case resetAt = "reset_at"
    }
}

struct FeatureFlagsDTO: Decodable, Sendable, Equatable {
    let remoteSearch: Bool
    let imageFeed: Bool

    enum CodingKeys: String, CodingKey {
        case remoteSearch = "remote_search"
        case imageFeed = "image_feed"
    }
}
