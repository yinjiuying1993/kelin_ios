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
    let userID: UUID
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
    let awayUntil: Date?
    let studyUntil: Date?
    let lastInteractAt: Date
    let createdAt: Date
    let updatedAt: Date
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
}

struct MutationResourceDTO: Decodable, Sendable, Equatable {
    let type: String
    let id: UUID
    let version: Int
}

struct SessionPatchDTO: Decodable, Sendable, Equatable {
    let snapshotVersion: Int
    let spirit: SpiritDTO?
    let preferences: PreferencesDTO?
    let onboarding: OnboardingDTO?

    enum CodingKeys: String, CodingKey {
        case snapshotVersion = "snapshot_version"
        case spirit
        case preferences
        case onboarding
    }
}

struct MutationResultDTO: Decodable, Sendable, Equatable {
    let resource: MutationResourceDTO
    let patch: SessionPatchDTO
}
