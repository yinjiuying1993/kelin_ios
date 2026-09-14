import XCTest
@testable import Kelin

final class RoomRefreshRulesTests: XCTestCase {
    func testShouldCrossFadeWhenVisualContentChanges() {
        let home = sampleScene(status: .home, isOffline: false)
        let study = sampleScene(status: .study, isOffline: false)

        XCTAssertTrue(RoomRefreshRules.shouldCrossFade(from: home, to: study))
    }

    func testShouldNotCrossFadeWhenOnlyOfflineOverlayChanges() {
        let online = sampleScene(status: .away, isOffline: false)
        let offline = sampleScene(status: .away, isOffline: true)

        XCTAssertFalse(RoomRefreshRules.shouldCrossFade(from: online, to: offline))
        XCTAssertEqual(online.primaryState, offline.primaryState)
        XCTAssertNotEqual(online.isOffline, offline.isOffline)
    }

    func testShouldRefreshAfterForegroundInterval() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let recent = now.addingTimeInterval(-(RoomRefreshRules.foregroundRefreshInterval - 30))
        let stale = now.addingTimeInterval(-(RoomRefreshRules.foregroundRefreshInterval + 1))

        XCTAssertFalse(RoomRefreshRules.shouldRefresh(lastRefreshAt: recent, now: now))
        XCTAssertTrue(RoomRefreshRules.shouldRefresh(lastRefreshAt: stale, now: now))
        XCTAssertTrue(RoomRefreshRules.shouldRefresh(lastRefreshAt: nil, now: now))
    }

    private func sampleScene(status: SpiritStatus, isOffline: Bool) -> RoomSceneModel {
        RoomRules.makeScene(
            from: RoomRulesInput(
                spirit: sampleSpirit(status: status),
                room: sampleRoom(),
                cachedWeather: "cloudy",
                isOffline: isOffline
            )
        )
    }

    private func sampleSpirit(status: SpiritStatus) -> Spirit {
        Spirit(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            userID: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
            name: "雾生",
            egg: .warm,
            inviteCode: "ABCD2345",
            traits: TraitValues(closeness: 65, curiosity: 55, sharpness: 35, nocturnal: 40, stubborn: 40),
            vitals: VitalValues(hunger: 80, energy: 80, mood: 60, bond: 0),
            stage: .whelp,
            status: status,
            scholarMarks: ["reader"],
            preferences: SpiritPreferences(
                ttsOn: false,
                pushOn: false,
                visitOn: true,
                dndStart: "23:00",
                dndEnd: "08:00",
                timezone: "Asia/Shanghai",
                defaultCity: nil,
                locationWeatherOn: false,
                remoteSearchOn: true
            ),
            awayUntil: nil,
            studyUntil: nil,
            lastInteractAt: Date(timeIntervalSince1970: 1_700_000_000),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            version: 1
        )
    }

    private func sampleRoom() -> RoomSnapshot {
        RoomSnapshot(
            weather: "cloudy",
            layers: [RoomLayer(key: "bookshelf", variant: "default")],
            letter: nil,
            pendingSightID: nil,
            unreadFootprintCount: 1,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}

@MainActor
final class RoomRefreshViewModelTests: XCTestCase {
    func testOfflineOverlayUpdatesWithoutCrossfade() {
        let viewModel = makeViewModel(status: .home, isOffline: false)

        let effect = viewModel.applySnapshotUpdate(
            spirit: makeSpirit(status: .home),
            room: makeRoom(),
            isOffline: true,
            animated: true
        )

        XCTAssertEqual(effect, .immediate)
        XCTAssertNil(viewModel.outgoingScene)
        XCTAssertEqual(viewModel.scene.primaryState, .home)
        XCTAssertTrue(viewModel.scene.isOffline)
        XCTAssertEqual(viewModel.scene.offlineBannerText, String(localized: "连不上，房间还在"))
    }

    func testVisualRefreshStartsCrossfadeAndKeepsPreviousSceneVisible() {
        let viewModel = makeViewModel(status: .home, isOffline: false)
        let previousIdentity = RoomRefreshRules.visualIdentity(for: viewModel.scene)

        let effect = viewModel.applySnapshotUpdate(
            spirit: makeSpirit(status: .study),
            room: makeRoom(),
            isOffline: false,
            animated: true
        )

        XCTAssertEqual(effect, .crossfade)
        XCTAssertNotNil(viewModel.outgoingScene)
        XCTAssertEqual(
            RoomRefreshRules.visualIdentity(for: viewModel.outgoingScene!),
            previousIdentity
        )
        XCTAssertEqual(viewModel.scene.primaryState, .study)
    }

    func testUnchangedSnapshotDoesNotClearScene() {
        let viewModel = makeViewModel(status: .home, isOffline: false)
        let before = viewModel.scene

        let effect = viewModel.applySnapshotUpdate(
            spirit: makeSpirit(status: .home),
            room: makeRoom(),
            isOffline: false,
            animated: true
        )

        XCTAssertEqual(effect, .unchanged)
        XCTAssertEqual(viewModel.scene, before)
    }

    private func makeViewModel(status: SpiritStatus, isOffline: Bool) -> RoomViewModel {
        RoomViewModel(
            spirit: makeSpirit(status: status),
            room: makeRoom(),
            isOffline: isOffline
        )
    }

    private func makeSpirit(status: SpiritStatus) -> Spirit {
        Spirit(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            userID: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
            name: "雾生",
            egg: .warm,
            inviteCode: "ABCD2345",
            traits: TraitValues(closeness: 65, curiosity: 55, sharpness: 35, nocturnal: 40, stubborn: 40),
            vitals: VitalValues(hunger: 80, energy: 80, mood: 60, bond: 0),
            stage: .whelp,
            status: status,
            scholarMarks: ["reader"],
            preferences: SpiritPreferences(
                ttsOn: false,
                pushOn: false,
                visitOn: true,
                dndStart: "23:00",
                dndEnd: "08:00",
                timezone: "Asia/Shanghai",
                defaultCity: nil,
                locationWeatherOn: false,
                remoteSearchOn: true
            ),
            awayUntil: nil,
            studyUntil: nil,
            lastInteractAt: Date(timeIntervalSince1970: 1_700_000_000),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            version: 1
        )
    }

    private func makeRoom() -> RoomSnapshot {
        RoomSnapshot(
            weather: "cloudy",
            layers: [RoomLayer(key: "bookshelf", variant: "default")],
            letter: nil,
            pendingSightID: nil,
            unreadFootprintCount: 1,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
