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

    private func mergeQuotas(current: [QuotaEntry], incoming: [QuotaEntry]?) -> [QuotaEntry] {
        guard let incoming, !incoming.isEmpty else {
            return current
        }

        var merged = current
        for entry in incoming {
            if let index = merged.firstIndex(where: { $0.capability == entry.capability }) {
                merged[index] = entry
            } else {
                merged.append(entry)
            }
        }
        return merged
    }

    private func mergeMemories(
        _ current: [MemorySummary],
        upsert: [MemorySummary],
        tombstones: [MemoryTombstone],
        clearsAll: Bool
    ) -> [MemorySummary] {
        if clearsAll {
            return []
        }

        var byID = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        for memory in upsert {
            if memory.status == "deleted" || memory.status == "sealed" {
                byID.removeValue(forKey: memory.id)
            } else {
                byID[memory.id] = memory
            }
        }
        for tombstone in tombstones {
            byID.removeValue(forKey: tombstone.id)
        }
        return byID.values.sorted {
            if $0.createdAt != $1.createdAt {
                return $0.createdAt > $1.createdAt
            }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    func replaceReport(_ report: ReportSnapshot) {
        guard let current = snapshot else { return }
        snapshot = BootstrapSnapshot(
            schemaVersion: current.schemaVersion,
            snapshotVersion: current.snapshotVersion,
            apiVersion: current.apiVersion,
            spirit: current.spirit,
            room: current.room,
            onboarding: current.onboarding,
            latestMemories: current.latestMemories,
            unreadPostcards: current.unreadPostcards,
            activePact: current.activePact,
            report: report,
            quotas: current.quotas,
            featureFlags: current.featureFlags,
            serverTime: current.serverTime
        )
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
            latestMemories: mergeMemories(
                current.latestMemories,
                upsert: patch.memoriesUpsert,
                tombstones: patch.memoryTombstones,
                clearsAll: patch.clearsAllMemories
            ),
            unreadPostcards: current.unreadPostcards,
            activePact: patch.pact ?? current.activePact,
            report: patch.report ?? current.report,
            quotas: mergeQuotas(current: current.quotas, incoming: patch.quotas),
            featureFlags: current.featureFlags,
            serverTime: patch.serverTime ?? current.serverTime
        )
    }
}
