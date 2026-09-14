import XCTest
@testable import Kelin

final class RoomRulesTests: XCTestCase {
    func testHomeSceneMapsWeatherFootprintsAndSpiritVisibility() {
        let scene = RoomRules.makeScene(
            from: RoomRulesInput(
                spirit: sampleSpirit(status: .home),
                room: sampleRoom(
                    weather: "cloudy",
                    layers: [RoomLayer(key: "floor", variant: "default")],
                    unreadFootprintCount: 2
                ),
                cachedWeather: nil,
                isOffline: false
            )
        )

        XCTAssertEqual(scene.primaryState, .home)
        XCTAssertEqual(scene.weather, .cloudy)
        XCTAssertTrue(scene.spiritVisible)
        XCTAssertEqual(scene.dimmingFactor, 1.0)
        XCTAssertEqual(scene.title, "雾生")
        XCTAssertEqual(scene.statusText, "\(String(localized: "阴天")) · \(String(localized: "门口有足迹"))")
        XCTAssertEqual(scene.unreadFootprints, 2)
        XCTAssertEqual(scene.primaryDockAction, .chat)
        XCTAssertNil(scene.offlineBannerText)
    }

    func testStudyAwayAndLostScenesMapDistinctPresentation() {
        let study = RoomRules.makeScene(
            from: RoomRulesInput(
                spirit: sampleSpirit(status: .study),
                room: sampleRoom(weather: "rain"),
                cachedWeather: nil,
                isOffline: false
            )
        )
        let away = RoomRules.makeScene(
            from: RoomRulesInput(
                spirit: sampleSpirit(status: .away),
                room: sampleRoom(weather: "clear"),
                cachedWeather: nil,
                isOffline: false
            )
        )
        let lost = RoomRules.makeScene(
            from: RoomRulesInput(
                spirit: sampleSpirit(status: .lost),
                room: sampleRoom(weather: "cloudy"),
                cachedWeather: nil,
                isOffline: false
            )
        )

        XCTAssertEqual(study.primaryState, .study)
        XCTAssertFalse(study.spiritVisible)
        XCTAssertEqual(study.title, String(localized: "它出去学了"))
        XCTAssertEqual(study.primaryDockAction, .pact)

        XCTAssertEqual(away.primaryState, .away)
        XCTAssertFalse(away.spiritVisible)
        XCTAssertEqual(away.title, String(localized: "它去了朋友家"))
        XCTAssertEqual(away.primaryDockAction, .social)

        XCTAssertEqual(lost.primaryState, .lost)
        XCTAssertFalse(lost.spiritVisible)
        XCTAssertEqual(lost.title, String(localized: "它不在"))
        XCTAssertEqual(lost.statusText, String(localized: "房间里还留着一点温度"))
        XCTAssertEqual(lost.dimmingFactor, 0.82, accuracy: 0.001)
        XCTAssertEqual(lost.primaryDockAction, .recall)
    }

    func testOfflineOverlayDoesNotChangePrimaryState() {
        let scene = RoomRules.makeScene(
            from: RoomRulesInput(
                spirit: sampleSpirit(status: .away),
                room: sampleRoom(weather: "cloudy"),
                cachedWeather: nil,
                isOffline: true
            )
        )

        XCTAssertEqual(scene.primaryState, .away)
        XCTAssertTrue(scene.isOffline)
        XCTAssertEqual(scene.offlineBannerText, String(localized: "连不上，房间还在"))
        XCTAssertEqual(scene.title, String(localized: "它去了朋友家"))
        XCTAssertEqual(scene.primaryDockAction, .history)
    }

    func testUnknownAndMarkKeysAreDroppedWhileSpiritAndScholarMap() {
        let scene = RoomRules.makeScene(
            from: RoomRulesInput(
                spirit: sampleSpirit(status: .home),
                room: sampleRoom(
                    weather: "cloudy",
                    layers: [
                        RoomLayer(key: "interview-v1", variant: "default"),
                        RoomLayer(key: "mystery_prop", variant: ""),
                        RoomLayer(key: "floor", variant: "wet"),
                        RoomLayer(key: "spirit", variant: "default"),
                        RoomLayer(key: "scholar", variant: "default"),
                    ]
                ),
                cachedWeather: nil,
                isOffline: false
            )
        )

        XCTAssertEqual(scene.layers.map(\.key), ["floor", "spirit", "scholar"])
        XCTAssertEqual(scene.layers[0].assetName, "room_floor_wet")
        XCTAssertEqual(scene.layers[1].assetName, "room_spirit_default")
        XCTAssertEqual(scene.layers[1].zIndex, 55)
        XCTAssertEqual(scene.layers[2].assetName, "room_scholar_default")
        XCTAssertEqual(scene.layers[2].zIndex, 70)
    }

    func testWeatherFallsBackToCachedThenCloudy() {
        XCTAssertEqual(
            RoomRules.mapWeather(raw: nil, fallback: "rain"),
            .rain
        )
        XCTAssertEqual(
            RoomRules.mapWeather(raw: "not-a-weather", fallback: nil),
            .cloudy
        )
    }

    func testPrimaryStatePriorityUsesLostStudyAwayHome() {
        XCTAssertEqual(
            RoomRules.resolvePrimaryState(from: [.home, .away, .study, .lost]),
            .lost
        )
        XCTAssertEqual(
            RoomRules.resolvePrimaryState(from: [.home, .away, .study]),
            .study
        )
        XCTAssertEqual(
            RoomRules.resolvePrimaryState(from: [.home, .away]),
            .away
        )
    }

    func testLetterAndPendingSightMapWithoutPrivateContent() {
        let letterID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let scene = RoomRules.makeScene(
            from: RoomRulesInput(
                spirit: sampleSpirit(status: .lost),
                room: RoomSnapshot(
                    weather: "cloudy",
                    layers: [],
                    letter: "room.letter.lost",
                    pendingSightID: letterID,
                    unreadFootprintCount: 0,
                    updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
                ),
                cachedWeather: nil,
                isOffline: false
            )
        )

        XCTAssertEqual(scene.letter?.titleKey, "room.letter.lost")
        XCTAssertEqual(scene.letter?.displayTitle, String(localized: "我想起那盏坏掉的灯。"))
        XCTAssertEqual(scene.pendingSight?.id, letterID)
        XCTAssertEqual(scene.pendingSight?.assetName, "prop_pending_sight")
    }

    private func sampleSpirit(status: SpiritStatus) -> Spirit {
        Spirit(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            userID: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
            name: "雾生",
            egg: .warm,
            inviteCode: "ABCD2345",
            traits: TraitValues(
                closeness: 65,
                curiosity: 55,
                sharpness: 35,
                nocturnal: 40,
                stubborn: 40
            ),
            vitals: VitalValues(hunger: 80, energy: 80, mood: 60, bond: 0),
            stage: .whelp,
            status: status,
            scholarMarks: [],
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

    private func sampleRoom(
        weather: String,
        layers: [RoomLayer] = [],
        unreadFootprintCount: Int = 0
    ) -> RoomSnapshot {
        RoomSnapshot(
            weather: weather,
            layers: layers,
            letter: nil,
            pendingSightID: nil,
            unreadFootprintCount: unreadFootprintCount,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
