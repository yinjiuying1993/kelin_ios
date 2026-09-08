import Foundation

struct SessionPatch: Equatable, Sendable {
    let snapshotVersion: Int
    let spirit: Spirit?
    let preferences: SpiritPreferences?
    let room: RoomSnapshot?
    let onboarding: OnboardingState?
    let serverTime: Date?
}

enum SessionStoreError: Error, Equatable, Sendable {
    case missingSnapshot
    case stalePatch(currentVersion: Int, patchVersion: Int)
}
