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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 2
        snapshotVersion = try container.decode(Int.self, forKey: .snapshotVersion)
        apiVersion = try container.decodeIfPresent(String.self, forKey: .apiVersion) ?? "v1"
        spirit = try container.decodeIfPresent(SpiritDTO.self, forKey: .spirit)
        room = try container.decodeIfPresent(RoomSnapshotDTO.self, forKey: .room)
        onboarding = try container.decode(OnboardingDTO.self, forKey: .onboarding)
        latestMemories = (try? container.decodeIfPresent([MemorySummaryDTO].self, forKey: .latestMemories)) ?? []
        unreadPostcards = (try? container.decodeIfPresent([PostcardSummaryDTO].self, forKey: .unreadPostcards)) ?? []
        activePact = try? container.decodeIfPresent(PactSummaryDTO.self, forKey: .activePact)
        report = try container.decode(ReportSnapshotDTO.self, forKey: .report)
        quotas = (try? container.decodeIfPresent([QuotaEntryDTO].self, forKey: .quotas)) ?? []
        featureFlags = try container.decode(FeatureFlagsDTO.self, forKey: .featureFlags)
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        weather = try container.decode(String.self, forKey: .weather)
        layers = try container.decodeIfPresent([RoomLayerDTO].self, forKey: .layers) ?? []
        letter = Self.decodeLetter(from: container)
        pendingSight = try container.decodeIfPresent(PendingSightDTO.self, forKey: .pendingSight)
        unreadFootprintCount = try container.decodeIfPresent(Int.self, forKey: .unreadFootprintCount) ?? 0
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    private static func decodeLetter(
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> String? {
        if let text = try? container.decodeIfPresent(String.self, forKey: .letter) {
            return text
        }
        if let object = try? container.decodeIfPresent(RoomLetterDTO.self, forKey: .letter) {
            return object.titleKey
        }
        return nil
    }
}

struct RoomLayerDTO: Decodable, Sendable, Equatable {
    let key: String
    let variant: String

    init(key: String, variant: String) {
        self.key = key
        self.variant = variant
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let value = try? container.decode(String.self) {
            key = value
            variant = "default"
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        variant = try container.decodeIfPresent(String.self, forKey: .variant) ?? "default"
    }

    private enum CodingKeys: String, CodingKey {
        case key
        case variant
    }
}

struct RoomLetterDTO: Decodable, Sendable, Equatable {
    let titleKey: String

    enum CodingKeys: String, CodingKey {
        case titleKey = "title_key"
    }
}

struct PendingSightDTO: Decodable, Sendable, Equatable {
    let id: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case feedID = "feed_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try container.decodeIfPresent(UUID.self, forKey: .id) {
            self.id = id
        } else {
            id = try container.decode(UUID.self, forKey: .feedID)
        }
    }
}

struct MemorySummaryDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let type: String
    let summary: String
    let status: String
    let createdAt: Date
    let version: Int
    let tags: [String]
    let salience: Int
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case summary
        case status
        case createdAt = "created_at"
        case version
        case tags
        case salience
        case confidence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        summary = try container.decode(String.self, forKey: .summary)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
            ?? Date(timeIntervalSince1970: 0)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        salience = try container.decodeIfPresent(Int.self, forKey: .salience) ?? 0
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
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
    let card: ReportCardDTO?

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
