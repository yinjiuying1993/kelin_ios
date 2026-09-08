import Foundation

enum EggType: String, Codable, Sendable, CaseIterable {
    case warm
    case cold
    case wild
}

enum SpiritStage: String, Codable, Sendable {
    case whelp
    case formed
    case awake
}

enum SpiritStatus: String, Codable, Sendable {
    case home
    case away
    case study
    case lost
}

struct TraitValues: Equatable, Sendable, Codable {
    let closeness: Int
    let curiosity: Int
    let sharpness: Int
    let nocturnal: Int
    let stubborn: Int
}

struct VitalValues: Equatable, Sendable, Codable {
    let hunger: Int
    let energy: Int
    let mood: Int
    let bond: Int
}

struct SpiritPreferences: Equatable, Sendable, Codable {
    let ttsOn: Bool
    let pushOn: Bool
    let visitOn: Bool
    let dndStart: String
    let dndEnd: String
    let timezone: String
    let defaultCity: String?
    let locationWeatherOn: Bool
    let remoteSearchOn: Bool
}

struct Spirit: Equatable, Sendable, Identifiable, Codable {
    let id: UUID
    let userID: UUID
    var name: String
    let egg: EggType
    let inviteCode: String
    var traits: TraitValues
    var vitals: VitalValues
    var stage: SpiritStage
    var status: SpiritStatus
    var scholarMarks: [String]
    var preferences: SpiritPreferences
    var awayUntil: Date?
    var studyUntil: Date?
    var lastInteractAt: Date
    var createdAt: Date
    var updatedAt: Date
    var version: Int
}

struct OnboardingState: Equatable, Sendable, Codable {
    let required: Bool
    let step: Int
    let totalSteps: Int
    let completedAt: Date?
}

struct CreateSpiritConsents: Equatable, Sendable {
    struct Disclosure: Equatable, Sendable {
        let documentVersion: String
        let explicitlyAccepted: Bool
    }

    struct DisplayedDocument: Equatable, Sendable {
        let documentVersion: String
        let displayed: Bool
    }

    let aiDisclosure: Disclosure
    let dataNotice: DisplayedDocument
    let userTerms: DisplayedDocument
}

struct CreateSpiritResult: Equatable, Sendable {
    let spirit: Spirit
    let onboarding: OnboardingState
    let snapshotVersion: Int
}
