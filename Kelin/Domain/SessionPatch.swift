import Foundation

struct SessionPatch: Equatable, Sendable {
    let snapshotVersion: Int
    let spirit: Spirit?
    let preferences: SpiritPreferences?
    let room: RoomSnapshot?
    let onboarding: OnboardingState?
    let memoriesUpsert: [MemorySummary]
    let memoryTombstones: [MemoryTombstone]
    let clearsAllMemories: Bool
    let quotas: [QuotaEntry]?
    let pact: PactSummary?
    let social: SocialPatchSnapshot?
    let postcardsUpsert: [Postcard]
    let report: ReportSnapshot?
    let serverTime: Date?

    init(
        snapshotVersion: Int,
        spirit: Spirit?,
        preferences: SpiritPreferences?,
        room: RoomSnapshot?,
        onboarding: OnboardingState?,
        memoriesUpsert: [MemorySummary] = [],
        memoryTombstones: [MemoryTombstone] = [],
        clearsAllMemories: Bool = false,
        quotas: [QuotaEntry]? = nil,
        pact: PactSummary? = nil,
        social: SocialPatchSnapshot? = nil,
        postcardsUpsert: [Postcard] = [],
        report: ReportSnapshot? = nil,
        serverTime: Date?
    ) {
        self.snapshotVersion = snapshotVersion
        self.spirit = spirit
        self.preferences = preferences
        self.room = room
        self.onboarding = onboarding
        self.memoriesUpsert = memoriesUpsert
        self.memoryTombstones = memoryTombstones
        self.clearsAllMemories = clearsAllMemories
        self.quotas = quotas
        self.pact = pact
        self.social = social
        self.postcardsUpsert = postcardsUpsert
        self.report = report
        self.serverTime = serverTime
    }
}

enum SessionStoreError: Error, Equatable, Sendable {
    case missingSnapshot
    case stalePatch(currentVersion: Int, patchVersion: Int)
}
