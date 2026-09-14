import Foundation

enum MemoryCacheRules {
    static func merge(
        existing: [MemorySummary],
        incoming: [MemorySummary],
        tombstones: [MemoryTombstone]
    ) -> [MemorySummary] {
        var byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        for memory in incoming {
            byID[memory.id] = memory
        }
        let hidden = Set(tombstones.map(\.id))
        return byID.values
            .filter { MemoryPresentationRules.isListable($0) && !hidden.contains($0.id) }
            .sorted(by: Self.isNewest)
    }

    static func applyMutation(
        existing: [MemorySummary],
        mutation: MemoryMutation
    ) -> [MemorySummary] {
        if mutation.patch.clearsAllMemories || mutation.resourceType == "memory_clear" {
            return []
        }
        return merge(
            existing: existing,
            incoming: mutation.patch.memoriesUpsert,
            tombstones: mutation.patch.memoryTombstones
        )
    }

    static func rejectResurrection(
        _ memories: [MemorySummary],
        hiddenIDs: Set<UUID>
    ) -> [MemorySummary] {
        memories.filter { memory in
            MemoryPresentationRules.isListable(memory) && !hiddenIDs.contains(memory.id)
        }
    }

    static func hiddenIDs(
        active: [MemorySummary],
        tombstones: [MemoryTombstone]
    ) -> Set<UUID> {
        var ids = Set(tombstones.map(\.id))
        for memory in active where !MemoryPresentationRules.isListable(memory) {
            ids.insert(memory.id)
        }
        return ids
    }

    private static func isNewest(_ lhs: MemorySummary, _ rhs: MemorySummary) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }
        return lhs.id.uuidString > rhs.id.uuidString
    }
}
