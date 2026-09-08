import Foundation

struct RoomLayer: Equatable, Sendable {
    let key: String
    let variant: String
}

struct RoomSnapshot: Equatable, Sendable {
    let weather: String
    let layers: [RoomLayer]
    let letter: String?
    let pendingSightID: UUID?
    let unreadFootprintCount: Int
    let updatedAt: Date
}

enum ReportStatus: String, Sendable, CaseIterable {
    case locked
    case generating
    case partial
    case ready
    case failed
}

struct ReportEligibility: Equatable, Sendable {
    let isEligible: Bool
    let eligibleAt: Date
    let daysRemaining: Int
    let requiredDialogueRounds: Int
    let completedDialogueRounds: Int
    let dialogueRoundsRemaining: Int
}

struct ReportSnapshot: Equatable, Sendable {
    let status: ReportStatus
    let reportID: UUID?
    let eligibility: ReportEligibility
}

struct QuotaEntry: Equatable, Sendable {
    let capability: QuotaKind
    let used: Int
    let limit: Int
    let resetAt: Date
}

struct FeatureFlags: Equatable, Sendable {
    let remoteSearch: Bool
    let imageFeed: Bool
}

struct MemorySummary: Equatable, Sendable, Identifiable {
    let id: UUID
    let type: String
    let summary: String
    let status: String
    let createdAt: Date
}

struct PostcardSummary: Equatable, Sendable, Identifiable {
    let id: UUID
    let text: String
    let createdAt: Date
}

struct PactSummary: Equatable, Sendable, Identifiable {
    let id: UUID
    let theme: String
    let title: String
    let status: String
}

struct BootstrapSnapshot: Equatable, Sendable {
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
