import Foundation

actor MockMemoryService: MemoryServiceProtocol {
    private var items: [MemorySummary]
    private var tombstones: [MemoryTombstone]
    private var seenClientIDs: [UUID: String] = [:]
    private var results: [UUID: MemoryMutation] = [:]

    init(items: [MemorySummary] = [], tombstones: [MemoryTombstone] = []) {
        self.items = items
        self.tombstones = tombstones
    }

    func list(filter: MemoryFilter, cursor: String?, limit: Int) async throws -> MemoryPage {
        if let cursor, cursor.hasPrefix("kelin.msg.") {
            throw AppError.invalidCursor
        }

        let visible = items.filter { MemoryPresentationRules.matches($0, filter: filter) }
        let start = cursor.flatMap { value in visible.firstIndex(where: { $0.id.uuidString == value }) }
            .map { $0 + 1 } ?? 0
        let end = min(start + limit, visible.count)
        let page = start < visible.count ? Array(visible[start..<end]) : []
        let hasMore = end < visible.count

        return MemoryPage(
            items: page,
            tombstones: tombstones,
            nextCursor: hasMore ? page.last?.id.uuidString : nil,
            hasMore: hasMore,
            snapshotAt: Date(timeIntervalSince1970: 1_778_000_000)
        )
    }

    func correct(
        id: UUID,
        expectedVersion: Int,
        summary: String,
        clientID: UUID
    ) async throws -> MemoryMutation {
        if let replay = try replay(clientID: clientID, body: "correct:\(id):\(expectedVersion):\(summary)") {
            return replay
        }
        guard var memory = items.first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        guard memory.status == "active" else {
            throw AppError.conflict
        }
        guard memory.version == expectedVersion else {
            throw AppError.conflict
        }
        memory = MemorySummary(
            id: memory.id,
            type: memory.type,
            summary: summary,
            status: memory.status,
            createdAt: memory.createdAt,
            version: memory.version + 1,
            tags: memory.tags,
            salience: memory.salience,
            confidence: memory.confidence
        )
        replace(memory)
        let result = mutation(for: memory, status: "active")
        results[clientID] = result
        seenClientIDs[clientID] = "correct:\(id):\(expectedVersion):\(summary)"
        return result
    }

    func seal(id: UUID, expectedVersion: Int, clientID: UUID) async throws -> MemoryMutation {
        if let replay = try replay(clientID: clientID, body: "seal:\(id):\(expectedVersion)") {
            return replay
        }
        guard var memory = items.first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        guard memory.status == "active" else {
            throw AppError.conflict
        }
        guard memory.version == expectedVersion else {
            throw AppError.conflict
        }
        memory = MemorySummary(
            id: memory.id,
            type: memory.type,
            summary: memory.summary,
            status: "sealed",
            createdAt: memory.createdAt,
            version: memory.version + 1,
            tags: memory.tags,
            salience: memory.salience,
            confidence: memory.confidence
        )
        items.removeAll { $0.id == id }
        let result = mutation(for: memory, status: "sealed")
        results[clientID] = result
        seenClientIDs[clientID] = "seal:\(id):\(expectedVersion)"
        return result
    }

    func delete(id: UUID, expectedVersion: Int, clientID: UUID) async throws -> MemoryMutation {
        if let replay = try replay(clientID: clientID, body: "delete:\(id):\(expectedVersion)") {
            return replay
        }
        let tombstone = MemoryTombstone(id: id, deletedAt: Date(timeIntervalSince1970: 1_778_000_100))
        items.removeAll { $0.id == id }
        if !tombstones.contains(where: { $0.id == id }) {
            tombstones.append(tombstone)
        }
        let result = MemoryMutation(
            resourceType: "memory",
            resourceID: id,
            resourceStatus: "deleted",
            patch: SessionPatch(
                snapshotVersion: 2,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                memoryTombstones: [tombstone],
                serverTime: tombstone.deletedAt
            )
        )
        results[clientID] = result
        seenClientIDs[clientID] = "delete:\(id):\(expectedVersion)"
        return result
    }

    func clearAll(clientID: UUID) async throws -> MemoryMutation {
        if let replay = try replay(clientID: clientID, body: "clear:\(MemoryMutationRules.clearConfirm)") {
            return replay
        }
        items = []
        tombstones = []
        let result = MemoryMutation(
            resourceType: "memory_clear",
            resourceID: clientID,
            resourceStatus: nil,
            patch: SessionPatch(
                snapshotVersion: 3,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                clearsAllMemories: true,
                serverTime: Date(timeIntervalSince1970: 1_778_000_200)
            )
        )
        results[clientID] = result
        seenClientIDs[clientID] = "clear:\(MemoryMutationRules.clearConfirm)"
        return result
    }

    private func replace(_ memory: MemorySummary) {
        if let index = items.firstIndex(where: { $0.id == memory.id }) {
            items[index] = memory
        } else {
            items.insert(memory, at: 0)
        }
    }

    private func mutation(for memory: MemorySummary, status: String) -> MemoryMutation {
        MemoryMutation(
            resourceType: "memory",
            resourceID: memory.id,
            resourceStatus: status,
            patch: SessionPatch(
                snapshotVersion: 2,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                memoriesUpsert: [memory],
                serverTime: memory.createdAt
            )
        )
    }

    private func replay(clientID: UUID, body: String) throws -> MemoryMutation? {
        if let existing = seenClientIDs[clientID] {
            if existing != body {
                throw AppError.conflict
            }
            return results[clientID]
        }
        return nil
    }
}
