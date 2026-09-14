import XCTest
@testable import Kelin

final class RoomHotspotTests: XCTestCase {
    func testAllHotspotsHaveVoiceOverLabelAndHint() {
        for hotspot in RoomHotspot.allCases {
            XCTAssertFalse(
                RoomHotspotRules.accessibilityLabel(for: hotspot).isEmpty,
                "missing label: \(hotspot.rawValue)"
            )
            XCTAssertFalse(
                RoomHotspotRules.accessibilityHint(for: hotspot).isEmpty,
                "missing hint: \(hotspot.rawValue)"
            )
        }
    }

    func testHotspotMinimumTouchTargetIsAtLeast44() {
        XCTAssertGreaterThanOrEqual(RoomHotspotRules.minimumTouchTarget, 44)
        XCTAssertEqual(RoomHotspotRules.minimumTouchTarget, KelinSize.minimumTouchTarget)
    }

    func testDockKeepsExactlyThreeEntries() {
        XCTAssertEqual(RoomHotspotRules.dockEntryCount, 3)
        XCTAssertLessThanOrEqual(RoomHotspotRules.dockEntryCount, 3)
    }

    func testMoreMenuHasFourSecondaryDestinations() {
        XCTAssertEqual(
            RoomHotspotRules.moreMenuDestinations,
            [.memory, .pact, .report, .settings]
        )
    }

    func testStaticHotspotDestinationsMatchS01() {
        XCTAssertEqual(RoomHotspotRules.action(for: .eyeMark), .showMarkOrigin(.eye))
        XCTAssertEqual(RoomHotspotRules.action(for: .scholarRune), .showMarkOrigin(.scholar))
        XCTAssertEqual(RoomHotspotRules.action(for: .paperNote), .showPaperNote)
        XCTAssertEqual(RoomHotspotRules.action(for: .footprint), .openSocial)
        XCTAssertEqual(RoomHotspotRules.action(for: .artifact), .showSightMemory)
        XCTAssertEqual(RoomHotspotRules.action(for: .bookshelf), .openPact)
        XCTAssertEqual(RoomHotspotRules.action(for: .more), .showMoreMenu)
    }

    func testSpiritFirstTapShowsBubbleSecondTapOpensChat() {
        var session = RoomSpiritTapSession()
        XCTAssertEqual(session.registerTap(), .showSpiritDialogue)
        XCTAssertEqual(session.tapCount, 1)
        XCTAssertEqual(session.registerTap(), .openChat)
        XCTAssertEqual(session.tapCount, 0)
    }

    func testSpiritSingleTapExpiresWithoutEnteringChat() {
        var session = RoomSpiritTapSession()
        XCTAssertEqual(session.registerTap(), .showSpiritDialogue)
        session.expireIfSingleTap()
        XCTAssertEqual(session.tapCount, 0)
        XCTAssertEqual(session.registerTap(), .showSpiritDialogue)
    }

    func testSpiritTapSessionIsPageLocalAndResettable() {
        var session = RoomSpiritTapSession()
        _ = session.registerTap()
        session.reset()
        XCTAssertEqual(session.registerTap(), .showSpiritDialogue)
    }

    func testPaperNoteTabFollowsLetterPriority() {
        XCTAssertEqual(
            RoomHotspotRules.defaultPaperNoteTab(
                for: RoomLetter(titleKey: "room.letter.lost", displayTitle: "lost")
            ),
            .lost
        )
        XCTAssertEqual(
            RoomHotspotRules.defaultPaperNoteTab(
                for: RoomLetter(titleKey: "room.letter.visit", displayTitle: "visit")
            ),
            .visit
        )
        XCTAssertEqual(
            RoomHotspotRules.defaultPaperNoteTab(
                for: RoomLetter(titleKey: "room.letter.pact", displayTitle: "pact")
            ),
            .contract
        )
        XCTAssertEqual(RoomHotspotRules.defaultPaperNoteTab(for: nil), .contract)
    }
}

@MainActor
final class RoomHotspotViewModelTests: XCTestCase {
    func testViewModelSpiritTapSequencePushesChatOnSecondTap() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.registerSpiritTap(), .showSpiritDialogue)
        XCTAssertNotNil(viewModel.dialogueLine)
        XCTAssertEqual(viewModel.registerSpiritTap(), .openChat)
        XCTAssertNil(viewModel.dialogueLine)
    }

    func testViewModelExpiresDialogueAfterTimeoutWindow() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.registerSpiritTap(), .showSpiritDialogue)
        viewModel.expireSpiritDialogueIfNeeded()
        XCTAssertNil(viewModel.dialogueLine)
        XCTAssertEqual(viewModel.registerSpiritTap(), .showSpiritDialogue)
    }

    private func makeViewModel() -> RoomViewModel {
        RoomViewModel(
            spirit: Spirit(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
                userID: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
                name: "雾生",
                egg: .warm,
                inviteCode: "ABCD2345",
                traits: TraitValues(closeness: 65, curiosity: 55, sharpness: 35, nocturnal: 40, stubborn: 40),
                vitals: VitalValues(hunger: 80, energy: 80, mood: 60, bond: 0),
                stage: .whelp,
                status: .home,
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
            ),
            room: nil,
            isOffline: false
        )
    }
}
