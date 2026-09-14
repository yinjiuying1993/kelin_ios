import XCTest
@testable import Kelin

final class MemoryMutationTests: XCTestCase {
    func testSummaryBounds() {
        XCTAssertThrowsError(try MemoryMutationRules.validateSummary(""))
        XCTAssertThrowsError(try MemoryMutationRules.validateSummary(String(repeating: "啊", count: 501)))
        XCTAssertEqual(try MemoryMutationRules.validateSummary("阿"), "阿")
        XCTAssertEqual(
            try MemoryMutationRules.validateSummary(String(repeating: "阿", count: 500)).count,
            500
        )
    }

    func testClearAllRequiresOnline() {
        XCTAssertFalse(MemoryMutationRules.canClearAll(isOffline: true))
        XCTAssertTrue(MemoryMutationRules.canClearAll(isOffline: false))
        XCTAssertEqual(MemoryMutationRules.clearConfirm, "CLEAR_ALL_MEMORIES")
    }

    func testMockCorrectIsIdempotentForSameClientID() async throws {
        let service = MockMemoryService(items: [MemoryDraftFixtures.preference])
        let clientID = UUID(uuidString: "70000000-0000-4000-8000-000000000001")!
        let first = try await service.correct(
            id: MemoryDraftFixtures.preference.id,
            expectedVersion: 1,
            summary: "请叫我阿年",
            clientID: clientID
        )
        let second = try await service.correct(
            id: MemoryDraftFixtures.preference.id,
            expectedVersion: 1,
            summary: "请叫我阿年",
            clientID: clientID
        )
        XCTAssertEqual(first.patch.memoriesUpsert.first?.version, 2)
        XCTAssertEqual(second.patch.memoriesUpsert.first?.summary, "请叫我阿年")

        do {
            _ = try await service.correct(
                id: MemoryDraftFixtures.preference.id,
                expectedVersion: 2,
                summary: "换一个摘要",
                clientID: clientID
            )
            XCTFail("expected idempotency conflict")
        } catch AppError.conflict {
            // expected
        }
    }

    func testFilterChangeMustDropCursor() {
        let first = APIEndpoint.memories(filter: .all, cursor: "kelin.mem.v1.old", limit: 30)
        let changed = APIEndpoint.memories(filter: .relationship, cursor: nil, limit: 30)
        XCTAssertTrue(first.path.contains("cursor="))
        XCTAssertFalse(changed.path.contains("cursor="))
        XCTAssertTrue(changed.path.contains("filter=relationship"))
    }
}

@MainActor
final class MemorySessionPatchTests: XCTestCase {
    func testSessionStoreAppliesTombstoneAndClear() throws {
        let store = SessionStore()
        let snapshot = BootstrapSnapshot(
            schemaVersion: 2,
            snapshotVersion: 10,
            apiVersion: "v1",
            spirit: nil,
            room: nil,
            onboarding: OnboardingState(required: false, step: 5, totalSteps: 5, completedAt: Date()),
            latestMemories: MemoryDraftFixtures.s07Samples,
            unreadPostcards: [],
            activePact: nil,
            report: ReportSnapshot(
                status: .locked,
                reportID: nil,
                eligibility: ReportEligibility(
                    isEligible: false,
                    eligibleAt: Date(timeIntervalSince1970: 1_778_000_000),
                    daysRemaining: 7,
                    requiredDialogueRounds: 20,
                    completedDialogueRounds: 0,
                    dialogueRoundsRemaining: 20
                )
            ),
            quotas: [],
            featureFlags: FeatureFlags(remoteSearch: false, imageFeed: false),
            serverTime: Date()
        )
        store.replace(with: snapshot)

        try store.apply(
            SessionPatch(
                snapshotVersion: 11,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                memoryTombstones: [
                    MemoryTombstone(id: MemoryDraftFixtures.preference.id, deletedAt: Date()),
                ],
                serverTime: Date()
            )
        )
        XCTAssertFalse(store.snapshot?.latestMemories.contains(where: { $0.id == MemoryDraftFixtures.preference.id }) ?? true)

        try store.apply(
            SessionPatch(
                snapshotVersion: 12,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                clearsAllMemories: true,
                serverTime: Date()
            )
        )
        XCTAssertEqual(store.snapshot?.latestMemories, [])
    }
}
