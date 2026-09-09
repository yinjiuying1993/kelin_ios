import SwiftData
import XCTest
@testable import Kelin

@MainActor
final class LaunchBootstrapTests: XCTestCase {
    func testLaunchUsesCachedSnapshotBeforeOnlineRefresh() async throws {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let localStore = LocalStore(modelContainer: container)

        let cachedSnapshot = try makeFullUserSnapshot(version: 100)
        try await localStore.upsertBootstrap(
            CachedBootstrapRecord(
                accountUserID: userID,
                payloadData: try BootstrapCacheCodec.encode(cachedSnapshot),
                snapshotVersion: 100,
                updatedAt: cachedSnapshot.serverTime
            )
        )

        let onlineSnapshot = try makeFullUserSnapshot(version: 200)
        let bootstrap = MockBootstrapService(
            mode: .snapshot(onlineSnapshot),
            delay: .milliseconds(150)
        )
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                storedSession: AuthSession(
                    userID: userID,
                    accessToken: "existing-token",
                    expiresAt: Date().addingTimeInterval(3_600)
                )
            )
        )
        let appState = AppState(
            auth: auth,
            localStore: localStore,
            bootstrapService: bootstrap
        )

        appState.beginLaunch()
        await waitUntil({ appState.isShowingCachedSnapshot })

        XCTAssertEqual(appState.sessionStore.snapshot?.snapshotVersion, 100)
        XCTAssertEqual(appState.phase, .ready)

        await waitUntil({ !appState.isShowingCachedSnapshot }, timeout: .seconds(3))

        XCTAssertEqual(appState.sessionStore.snapshot?.snapshotVersion, 200)
        XCTAssertFalse(appState.isShowingCachedSnapshot)
        XCTAssertFalse(appState.isOffline)
    }

    func testBootstrapFailurePreservesCachedSnapshot() async throws {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let localStore = LocalStore(modelContainer: container)
        let cachedSnapshot = try makeFullUserSnapshot(version: 120)

        try await localStore.upsertBootstrap(
            CachedBootstrapRecord(
                accountUserID: userID,
                payloadData: try BootstrapCacheCodec.encode(cachedSnapshot),
                snapshotVersion: 120,
                updatedAt: cachedSnapshot.serverTime
            )
        )

        let bootstrap = MockBootstrapService(mode: .failure(.networkUnavailable))
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                storedSession: AuthSession(
                    userID: userID,
                    accessToken: "existing-token",
                    expiresAt: Date().addingTimeInterval(3_600)
                )
            )
        )
        let appState = AppState(
            auth: auth,
            localStore: localStore,
            bootstrapService: bootstrap
        )

        appState.beginLaunch()
        await waitUntil({ appState.isOffline })

        XCTAssertTrue(appState.isOffline)
        XCTAssertEqual(appState.sessionStore.snapshot?.snapshotVersion, 120)
        XCTAssertEqual(appState.sessionStore.snapshot?.spirit?.name, "雾生")
    }

    func testForeignAccountCacheIsNotLoaded() async throws {
        let accountA = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
        let accountB = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let localStore = LocalStore(modelContainer: container)

        let cachedForA = try makeFullUserSnapshot(version: 50, userID: accountA, name: "账号A")
        try await localStore.upsertBootstrap(
            CachedBootstrapRecord(
                accountUserID: accountA,
                payloadData: try BootstrapCacheCodec.encode(cachedForA),
                snapshotVersion: 50,
                updatedAt: cachedForA.serverTime
            )
        )

        let bootstrap = MockBootstrapService(mode: .newUser)
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                storedSession: AuthSession(
                    userID: accountB,
                    accessToken: "token-b",
                    expiresAt: Date().addingTimeInterval(3_600)
                )
            )
        )
        let appState = AppState(
            auth: auth,
            localStore: localStore,
            bootstrapService: bootstrap
        )

        appState.beginLaunch()
        await waitForPhase(.needsAgreement, in: appState)

        XCTAssertFalse(appState.isShowingCachedSnapshot)
        XCTAssertNil(appState.sessionStore.snapshot?.spirit)
    }

    func testBootstrapCoordinatorSingleFlight() async throws {
        let bootstrap = MockBootstrapService(mode: .fullUser, delay: .milliseconds(100))
        let coordinator = BootstrapCoordinator()

        async let first = coordinator.fetch(using: bootstrap)
        async let second = coordinator.fetch(using: bootstrap)
        _ = try await (first, second)

        let fetchCount = await bootstrap.fetchCountValue()
        XCTAssertEqual(fetchCount, 1)
    }

    func testDiscardLocalCacheReloadsFromBootstrap() async throws {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let localStore = LocalStore(modelContainer: container)
        let cachedSnapshot = try makeFullUserSnapshot(version: 120)

        try await localStore.upsertBootstrap(
            CachedBootstrapRecord(
                accountUserID: userID,
                payloadData: try BootstrapCacheCodec.encode(cachedSnapshot),
                snapshotVersion: 120,
                updatedAt: cachedSnapshot.serverTime
            )
        )

        let bootstrap = MockBootstrapService(mode: .failure(.networkUnavailable))
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                storedSession: AuthSession(
                    userID: userID,
                    accessToken: "existing-token",
                    expiresAt: Date().addingTimeInterval(3_600)
                )
            )
        )
        let appState = AppState(
            auth: auth,
            localStore: localStore,
            bootstrapService: bootstrap
        )

        appState.beginLaunch()
        await waitUntil({ appState.isOffline })
        XCTAssertEqual(appState.phase, .ready)

        await bootstrap.setMode(.newUser)
        await appState.discardLocalCacheAndReload()
        await waitForPhase(.needsAgreement, in: appState)

        XCTAssertNil(appState.sessionStore.snapshot?.spirit)
        XCTAssertFalse(appState.isOffline)
    }

    private func makeFullUserSnapshot(
        version: Int,
        userID: UUID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!,
        name: String = "雾生"
    ) throws -> BootstrapSnapshot {
        let envelope: APIEnvelope<BootstrapDataDTO> = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<BootstrapDataDTO>.self,
            from: Data(BootstrapDraftFixtures.fullUserEnvelope.utf8)
        )
        var snapshot = try BootstrapMapper.map(try XCTUnwrap(envelope.data), serverTime: envelope.serverTime)

        guard let baseSpirit = snapshot.spirit else {
            throw AppError.decoding
        }

        let spirit = Spirit(
            id: baseSpirit.id,
            userID: userID,
            name: name,
            egg: baseSpirit.egg,
            inviteCode: baseSpirit.inviteCode,
            traits: baseSpirit.traits,
            vitals: baseSpirit.vitals,
            stage: baseSpirit.stage,
            status: baseSpirit.status,
            scholarMarks: baseSpirit.scholarMarks,
            preferences: baseSpirit.preferences,
            awayUntil: baseSpirit.awayUntil,
            studyUntil: baseSpirit.studyUntil,
            lastInteractAt: baseSpirit.lastInteractAt,
            createdAt: baseSpirit.createdAt,
            updatedAt: baseSpirit.updatedAt,
            version: baseSpirit.version
        )

        return BootstrapSnapshot(
            schemaVersion: snapshot.schemaVersion,
            snapshotVersion: version,
            apiVersion: snapshot.apiVersion,
            spirit: spirit,
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
    }

    private func waitForPhase(
        _ expected: AppPhase,
        in appState: AppState,
        timeout: Duration = .seconds(2)
    ) async {
        let deadline = ContinuousClock.now + timeout

        while ContinuousClock.now < deadline {
            if appState.phase == expected {
                return
            }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }

        XCTFail("Expected phase \(expected), got \(appState.phase)")
    }

    private func waitUntil(
        _ predicate: @escaping @MainActor () -> Bool,
        timeout: Duration = .seconds(2)
    ) async {
        let deadline = ContinuousClock.now + timeout

        while ContinuousClock.now < deadline {
            if predicate() {
                return
            }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }

        XCTFail("Condition not met before timeout")
    }
}
