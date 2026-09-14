import Foundation

struct ConsentAcceptanceDTO: Codable, Sendable, Equatable {
    let documentVersion: String
    let explicitlyAccepted: Bool

    enum CodingKeys: String, CodingKey {
        case documentVersion = "document_version"
        case explicitlyAccepted = "explicitly_accepted"
    }
}

struct ConsentDisplayedDTO: Codable, Sendable, Equatable {
    let documentVersion: String
    let displayed: Bool

    enum CodingKeys: String, CodingKey {
        case documentVersion = "document_version"
        case displayed
    }
}

struct CreateSpiritConsentsDTO: Codable, Sendable, Equatable {
    let aiDisclosure: ConsentAcceptanceDTO
    let dataNotice: ConsentDisplayedDTO
    let userTerms: ConsentDisplayedDTO

    enum CodingKeys: String, CodingKey {
        case aiDisclosure = "ai_disclosure"
        case dataNotice = "data_notice"
        case userTerms = "user_terms"
    }
}

struct CreateSpiritRequestDTO: Codable, Sendable, Equatable {
    let clientID: UUID
    let egg: String
    let name: String
    let consents: CreateSpiritConsentsDTO

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case egg
        case name
        case consents
    }
}

struct SpiritDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let userID: UUID?
    let name: String
    let egg: String
    let inviteCode: String
    let closeness: Int
    let curiosity: Int
    let sharpness: Int
    let nocturnal: Int
    let stubborn: Int
    let hunger: Int
    let energy: Int
    let mood: Int
    let bond: Int
    let stage: String
    let status: String
    let scholarMarks: [String]
    let version: Int
    let onboardingStep: Int?
    let onboardingCompletedAt: Date?
    let awayUntil: Date?
    let studyUntil: Date?
    let lastInteractAt: Date?
    let createdAt: Date
    let updatedAt: Date?
    let hatchedAt: Date?
    let preferences: PreferencesDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case name
        case egg
        case inviteCode = "invite_code"
        case closeness
        case curiosity
        case sharpness
        case nocturnal
        case stubborn
        case hunger
        case energy
        case mood
        case bond
        case stage
        case status
        case scholarMarks = "scholar_marks"
        case version
        case onboardingStep = "onboarding_step"
        case onboardingCompletedAt = "onboarding_completed_at"
        case awayUntil = "away_until"
        case studyUntil = "study_until"
        case lastInteractAt = "last_interact_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case hatchedAt = "hatched_at"
        case preferences
    }
}

struct PreferencesDTO: Decodable, Sendable, Equatable {
    let ttsOn: Bool
    let pushOn: Bool
    let visitOn: Bool
    let dndStart: String
    let dndEnd: String
    let timezone: String
    let defaultCity: String?
    let locationWeatherOn: Bool
    let remoteSearchOn: Bool

    enum CodingKeys: String, CodingKey {
        case ttsOn = "tts_on"
        case pushOn = "push_on"
        case visitOn = "visit_on"
        case dndStart = "dnd_start"
        case dndEnd = "dnd_end"
        case timezone
        case defaultCity = "default_city"
        case locationWeatherOn = "location_weather_on"
        case remoteSearchOn = "remote_search_on"
    }
}

struct OnboardingDTO: Decodable, Sendable, Equatable {
    let required: Bool
    let step: Int
    let totalSteps: Int
    let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case required
        case step
        case totalSteps = "total_steps"
        case completedAt = "completed_at"
    }

    init(required: Bool, step: Int, totalSteps: Int, completedAt: Date?) {
        self.required = required
        self.step = step
        self.totalSteps = totalSteps
        self.completedAt = completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        required = try container.decode(Bool.self, forKey: .required)
        step = try container.decode(Int.self, forKey: .step)
        totalSteps = try container.decodeIfPresent(Int.self, forKey: .totalSteps) ?? 5
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
}

struct MutationResourceDTO: Decodable, Sendable, Equatable {
    let type: String
    let id: UUID
    let version: Int
    let status: String?

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case version
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "memory"
        id = try container.decode(UUID.self, forKey: .id)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        status = try container.decodeIfPresent(String.self, forKey: .status)
    }
}

struct SessionPatchDTO: Decodable, Sendable, Equatable {
    let snapshotVersion: Int
    let spirit: SpiritDTO?
    let preferences: PreferencesDTO?
    let room: RoomSnapshotDTO?
    let onboarding: OnboardingDTO?
    let memoriesUpsert: [MemorySummaryDTO]
    let memoryTombstones: [MemoryTombstoneDTO]
    let pact: PactResourceDTO?
    let social: SocialPatchDTO?
    let postcardsUpsert: [PostcardPublicDTO]
    let report: ReportSnapshotDTO?

    enum CodingKeys: String, CodingKey {
        case snapshotVersion = "snapshot_version"
        case spirit
        case preferences
        case room
        case onboarding
        case memoriesUpsert = "memories_upsert"
        case memoryTombstones = "memory_tombstones"
        case pact
        case social
        case postcardsUpsert = "postcards_upsert"
        case report
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        snapshotVersion = try container.decode(Int.self, forKey: .snapshotVersion)
        spirit = try container.decodeIfPresent(SpiritDTO.self, forKey: .spirit)
        preferences = try container.decodeIfPresent(PreferencesDTO.self, forKey: .preferences)
        room = try container.decodeIfPresent(RoomSnapshotDTO.self, forKey: .room)
        onboarding = try container.decodeIfPresent(OnboardingDTO.self, forKey: .onboarding)
        memoriesUpsert = try container.decodeIfPresent([MemorySummaryDTO].self, forKey: .memoriesUpsert) ?? []
        memoryTombstones = try container.decodeIfPresent([MemoryTombstoneDTO].self, forKey: .memoryTombstones) ?? []
        pact = try container.decodeIfPresent(PactResourceDTO.self, forKey: .pact)
        social = try container.decodeIfPresent(SocialPatchDTO.self, forKey: .social)
        postcardsUpsert = try container.decodeIfPresent([PostcardPublicDTO].self, forKey: .postcardsUpsert) ?? []
        report = try container.decodeIfPresent(ReportSnapshotDTO.self, forKey: .report)
    }
}

struct MutationResultDTO: Decodable, Sendable, Equatable {
    let resource: MutationResourceDTO
    let patch: SessionPatchDTO
}
