import XCTest
@testable import Kelin

final class MemoryCacheTests: XCTestCase {
    func testMergeDedupesByIDAndDropsTombstones() {
        let first = MemoryDraftFixtures.preference
        let updated = MemorySummary(
            id: first.id,
            type: first.type,
            summary: "请叫我阿年",
            status: first.status,
            createdAt: first.createdAt,
            version: 2
        )
        let merged = MemoryCacheRules.merge(
            existing: [first, MemoryDraftFixtures.knowledge],
            incoming: [updated],
            tombstones: [MemoryTombstone(id: MemoryDraftFixtures.knowledge.id, deletedAt: first.createdAt)]
        )

        XCTAssertEqual(merged.map(\.id), [first.id])
        XCTAssertEqual(merged.first?.summary, "请叫我阿年")
        XCTAssertEqual(merged.first?.version, 2)
    }

    func testClearMutationEmptiesCacheWithoutTombstones() {
        let mutation = MemoryMutation(
            resourceType: "memory_clear",
            resourceID: UUID(),
            resourceStatus: nil,
            patch: SessionPatch(
                snapshotVersion: 9,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                clearsAllMemories: true,
                serverTime: nil
            )
        )

        let remaining = MemoryCacheRules.applyMutation(
            existing: MemoryDraftFixtures.s07Samples,
            mutation: mutation
        )
        XCTAssertTrue(remaining.isEmpty)
    }

    func testOldBootstrapCannotResurrectHiddenIDs() {
        let hidden = Set([MemoryDraftFixtures.preference.id])
        let kept = MemoryCacheRules.rejectResurrection(
            MemoryDraftFixtures.s07Samples,
            hiddenIDs: hidden
        )
        XCTAssertFalse(kept.contains(where: { $0.id == MemoryDraftFixtures.preference.id }))
        XCTAssertEqual(kept.count, 2)
    }

    func testSourceBadgeHidesMemoryRefsOnly() {
        let memoryID = MemoryDraftFixtures.preference.id
        let refs = [
            MessageSourceRef(kind: "memory", title: "记忆", memoryID: memoryID),
            MessageSourceRef(kind: "web", title: "来源", memoryID: nil, url: "https://example.com"),
        ]
        let visible = MemoryCitationRules.visible(refs, hiddenMemoryIDs: [memoryID])
        XCTAssertEqual(visible.map(\.kind), ["web"])
    }
}
