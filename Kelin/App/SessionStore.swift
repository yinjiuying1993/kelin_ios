import Foundation

@MainActor
@Observable
final class SessionStore {
    private(set) var snapshot: BootstrapSnapshot?
    private(set) var needsBootstrapRefresh = false

    func replace(with snapshot: BootstrapSnapshot) {
        self.snapshot = snapshot
        needsBootstrapRefresh = false
    }

    func apply(_ patch: SessionPatch) throws {
        guard let current = snapshot else {
            throw SessionStoreError.missingSnapshot
        }

        guard patch.snapshotVersion >= current.snapshotVersion else {
            needsBootstrapRefresh = true
            throw SessionStoreError.stalePatch(
                currentVersion: current.snapshotVersion,
                patchVersion: patch.snapshotVersion
            )
        }

        snapshot = merge(current: current, patch: patch)
        needsBootstrapRefresh = false
    }

    func clear() {
        snapshot = nil
        needsBootstrapRefresh = false
    }

    private func merge(current: BootstrapSnapshot, patch: SessionPatch) -> BootstrapSnapshot {
        var updatedSpirit = current.spirit

        if let spirit = patch.spirit {
            updatedSpirit = spirit
        }

        if let preferences = patch.preferences, var spirit = updatedSpirit {
            spirit.preferences = preferences
            updatedSpirit = spirit
        }

        return BootstrapSnapshot(
            schemaVersion: current.schemaVersion,
            snapshotVersion: patch.snapshotVersion,
            apiVersion: current.apiVersion,
            spirit: updatedSpirit,
            room: patch.room ?? current.room,
            onboarding: patch.onboarding ?? current.onboarding,
            latestMemories: current.latestMemories,
            unreadPostcards: current.unreadPostcards,
            activePact: current.activePact,
            report: current.report,
            quotas: current.quotas,
            featureFlags: current.featureFlags,
            serverTime: patch.serverTime ?? current.serverTime
        )
    }
}
