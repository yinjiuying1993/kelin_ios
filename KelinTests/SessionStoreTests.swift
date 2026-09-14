import XCTest
@testable import Kelin

@MainActor
final class SessionStoreTests: XCTestCase {
    private var store: SessionStore!

    override func setUp() {
        super.setUp()
        store = SessionStore()
    }

    func testReplaceSetsSnapshotAndClearsRefreshFlag() throws {
        let snapshot = try makeOnboardingSnapshot(version: 12)

        store.replace(with: snapshot)

        XCTAssertEqual(store.snapshot, snapshot)
        XCTAssertFalse(store.needsBootstrapRefresh)
    }

    func testApplyHigherVersionPatchMergesFields() throws {
        let base = try makeOnboardingSnapshot(version: 12)
        store.replace(with: base)

        let updatedSpirit = try XCTUnwrap(base.spirit)
        var patchedSpirit = updatedSpirit
        patchedSpirit.name = "雾生"
        patchedSpirit.version = 13

        let patch = SessionPatch(
            snapshotVersion: 13,
            spirit: patchedSpirit,
            preferences: nil,
            room: RoomSnapshot(
                weather: "rain",
                layers: [RoomLayer(key: "floor", variant: "wet")],
                letter: nil,
                pendingSightID: nil,
                unreadFootprintCount: 1,
                updatedAt: base.serverTime
            ),
            onboarding: OnboardingState(
                required: true,
                step: 4,
                totalSteps: 5,
                completedAt: nil
            ),
            serverTime: base.serverTime.addingTimeInterval(60)
        )

        try store.apply(patch)

        XCTAssertEqual(store.snapshot?.snapshotVersion, 13)
        XCTAssertEqual(store.snapshot?.spirit?.name, "雾生")
        XCTAssertEqual(store.snapshot?.room?.weather, "rain")
        XCTAssertEqual(store.snapshot?.onboarding.step, 4)
        XCTAssertFalse(store.needsBootstrapRefresh)
    }

    func testApplySameVersionPatchStillMerges() throws {
        let base = try makeOnboardingSnapshot(version: 12)
        store.replace(with: base)

        let patch = SessionPatch(
            snapshotVersion: 12,
            spirit: nil,
            preferences: nil,
            room: nil,
            onboarding: OnboardingState(
                required: true,
                step: 4,
                totalSteps: 5,
                completedAt: nil
            ),
            serverTime: nil
        )

        try store.apply(patch)

        XCTAssertEqual(store.snapshot?.snapshotVersion, 12)
        XCTAssertEqual(store.snapshot?.onboarding.step, 4)
        XCTAssertEqual(store.snapshot?.room?.weather, "cloudy")
        XCTAssertFalse(store.needsBootstrapRefresh)
    }

    func testApplyStalePatchIsRejectedAndRequestsRefresh() throws {
        let base = try makeOnboardingSnapshot(version: 12)
        store.replace(with: base)

        let stalePatch = SessionPatch(
            snapshotVersion: 11,
            spirit: nil,
            preferences: nil,
            room: nil,
            onboarding: OnboardingState(
                required: true,
                step: 1,
                totalSteps: 5,
                completedAt: nil
            ),
            serverTime: nil
        )

        XCTAssertThrowsError(try store.apply(stalePatch)) { error in
            XCTAssertEqual(
                error as? SessionStoreError,
                .stalePatch(currentVersion: 12, patchVersion: 11)
            )
        }

        XCTAssertTrue(store.needsBootstrapRefresh)
        XCTAssertEqual(store.snapshot?.onboarding.step, 3)
    }

    func testApplyPatchWithoutSnapshotFails() {
        let patch = SessionPatch(
            snapshotVersion: 1,
            spirit: nil,
            preferences: nil,
            room: nil,
            onboarding: nil,
            serverTime: nil
        )

        XCTAssertThrowsError(try store.apply(patch)) { error in
            XCTAssertEqual(error as? SessionStoreError, .missingSnapshot)
        }
    }

    func testClearRemovesSnapshot() throws {
        store.replace(with: try makeOnboardingSnapshot(version: 12))

        store.clear()

        XCTAssertNil(store.snapshot)
        XCTAssertFalse(store.needsBootstrapRefresh)
    }

    func testApplyPreferencesOnlyPatchUpdatesExistingSpirit() throws {
        let base = try makeOnboardingSnapshot(version: 12)
        store.replace(with: base)

        let patch = SessionPatch(
            snapshotVersion: 13,
            spirit: nil,
            preferences: SpiritPreferences(
                ttsOn: true,
                pushOn: true,
                visitOn: false,
                dndStart: "22:00",
                dndEnd: "07:00",
                timezone: "Asia/Shanghai",
                defaultCity: "上海",
                locationWeatherOn: true,
                remoteSearchOn: false
            ),
            room: nil,
            onboarding: nil,
            serverTime: nil
        )

        try store.apply(patch)

        XCTAssertEqual(store.snapshot?.spirit?.preferences.ttsOn, true)
        XCTAssertEqual(store.snapshot?.spirit?.preferences.visitOn, false)
        XCTAssertEqual(store.snapshot?.snapshotVersion, 13)
    }

    func testApplyPatchMergesQuotasByCapabilityAndKeepsOmittedRows() throws {
        let base = try makeOnboardingSnapshot(version: 12)
        store.replace(with: base)
        let existingChat = QuotaEntry(
            capability: .chat,
            used: 4,
            limit: 100,
            resetAt: Date(timeIntervalSince1970: 1_778_000_000)
        )
        store.replace(
            with: BootstrapSnapshot(
                schemaVersion: base.schemaVersion,
                snapshotVersion: base.snapshotVersion,
                apiVersion: base.apiVersion,
                spirit: base.spirit,
                room: base.room,
                onboarding: base.onboarding,
                latestMemories: base.latestMemories,
                unreadPostcards: base.unreadPostcards,
                activePact: base.activePact,
                report: base.report,
                quotas: [
                    existingChat,
                    QuotaEntry(
                        capability: .food,
                        used: 0,
                        limit: 3,
                        resetAt: Date(timeIntervalSince1970: 1_778_000_000)
                    ),
                ],
                featureFlags: base.featureFlags,
                serverTime: base.serverTime
            )
        )

        let patch = SessionPatch(
            snapshotVersion: 13,
            spirit: nil,
            preferences: nil,
            room: nil,
            onboarding: nil,
            quotas: [
                QuotaEntry(
                    capability: .food,
                    used: 1,
                    limit: 3,
                    resetAt: Date(timeIntervalSince1970: 1_778_000_000)
                )
            ],
            serverTime: nil
        )

        try store.apply(patch)

        XCTAssertEqual(store.snapshot?.quotas.first { $0.capability == .chat }?.used, 4)
        XCTAssertEqual(store.snapshot?.quotas.first { $0.capability == .food }?.used, 1)
        XCTAssertEqual(store.snapshot?.room?.weather, "cloudy")
    }

    func testApplyOmittedOrEmptyQuotasKeepPreviousRows() throws {
        let base = try makeOnboardingSnapshot(version: 12)
        let withFood = BootstrapSnapshot(
            schemaVersion: base.schemaVersion,
            snapshotVersion: base.snapshotVersion,
            apiVersion: base.apiVersion,
            spirit: base.spirit,
            room: base.room,
            onboarding: base.onboarding,
            latestMemories: base.latestMemories,
            unreadPostcards: base.unreadPostcards,
            activePact: base.activePact,
            report: base.report,
            quotas: [
                QuotaEntry(
                    capability: .food,
                    used: 2,
                    limit: 3,
                    resetAt: Date(timeIntervalSince1970: 1_778_000_000)
                )
            ],
            featureFlags: base.featureFlags,
            serverTime: base.serverTime
        )
        store.replace(with: withFood)

        try store.apply(
            SessionPatch(
                snapshotVersion: 12,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                quotas: nil,
                serverTime: nil
            )
        )
        XCTAssertEqual(store.snapshot?.quotas.first?.used, 2)

        try store.apply(
            SessionPatch(
                snapshotVersion: 12,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                quotas: [],
                serverTime: nil
            )
        )
        XCTAssertEqual(store.snapshot?.quotas.first?.used, 2)
        XCTAssertEqual(store.snapshot?.room?.weather, "cloudy")
    }

    private func makeOnboardingSnapshot(version: Int) throws -> BootstrapSnapshot {
        let envelope: APIEnvelope<BootstrapDataDTO> = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<BootstrapDataDTO>.self,
            from: Data(BootstrapDraftFixtures.onboardingUserEnvelope.utf8)
        )
        var snapshot = try BootstrapMapper.map(try XCTUnwrap(envelope.data), serverTime: envelope.serverTime)
        snapshot = BootstrapSnapshot(
            schemaVersion: snapshot.schemaVersion,
            snapshotVersion: version,
            apiVersion: snapshot.apiVersion,
            spirit: snapshot.spirit,
            room: snapshot.room,
            onboarding: snapshot.onboarding,
            latestMemories: snapshot.latestMemories,
            unreadPostcards: snapshot.unreadPostcards,
            activePact: snapshot.activePact,
            report: snapshot.report,
            quotas: snapshot.quotas,
            featureFlags: snapshot.featureFlags,
            serverTime: snapshot.serverTime
        )
        return snapshot
    }
}
