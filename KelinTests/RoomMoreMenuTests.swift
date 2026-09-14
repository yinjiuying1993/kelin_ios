import XCTest
@testable import Kelin

final class RoomMoreMenuTests: XCTestCase {
    func testDrawerKeepsFourDocumentDestinations() {
        let model = RoomMoreMenuRules.make(
            spirit: sampleSpirit(),
            weather: .cloudy,
            latestMemories: [],
            activePact: nil,
            report: nil
        )

        XCTAssertEqual(
            RoomMoreMenuRules.destinations(in: model),
            RoomHotspotRules.moreMenuDestinations
        )
        XCTAssertEqual(
            model.rows.map(\.title),
            ["记忆", "共学", "七日鉴定", "设置"]
        )
        XCTAssertEqual(RoomMoreMenuModel.drawerWidth, 292)
    }

    func testEmptyStatesDoNotInventProgress() {
        let model = RoomMoreMenuRules.make(
            spirit: sampleSpirit(scholarMarks: []),
            weather: .cloudy,
            latestMemories: [],
            activePact: nil,
            report: nil
        )

        XCTAssertEqual(model.rows[0].subtitle, "还没有刻痕")
        XCTAssertFalse(model.rows[0].showsIndicator)
        XCTAssertEqual(model.rows[1].subtitle, "这一周还没有约定要学的事")
        XCTAssertEqual(model.rows[2].subtitle, "还在长")
        XCTAssertEqual(model.identityLine, "阴天")
        XCTAssertFalse(model.rows[2].subtitle.contains("4 / 7"))
    }

    func testRowsUseSnapshotFacts() {
        let model = RoomMoreMenuRules.make(
            spirit: sampleSpirit(stage: .formed, scholarMarks: ["reader"]),
            weather: .cloudy,
            latestMemories: [
                MemorySummary(
                    id: UUID(uuidString: "50000000-0000-4000-8000-000000000001")!,
                    type: "preference",
                    summary: "希望被叫阿年",
                    status: "active",
                    createdAt: Date(timeIntervalSince1970: 1_700_000_000)
                ),
                MemorySummary(
                    id: UUID(uuidString: "50000000-0000-4000-8000-000000000002")!,
                    type: "sight",
                    summary: "雨夜路灯",
                    status: "sealed",
                    createdAt: Date(timeIntervalSince1970: 1_700_000_100)
                ),
            ],
            activePact: PactSummary(
                id: UUID(uuidString: "60000000-0000-4000-8000-000000000001")!,
                theme: "面试题",
                title: "STAR 法则",
                status: "active"
            ),
            report: ReportSnapshot(
                status: .locked,
                reportID: nil,
                eligibility: ReportEligibility(
                    isEligible: false,
                    eligibleAt: Date(timeIntervalSince1970: 1_700_600_000),
                    daysRemaining: 3,
                    requiredDialogueRounds: 7,
                    completedDialogueRounds: 4,
                    dialogueRoundsRemaining: 3
                )
            ),
            now: Date(timeIntervalSince1970: 1_700_259_200),
            calendar: gmtCalendar
        )

        XCTAssertEqual(model.spiritName, "雾生")
        XCTAssertEqual(model.stageTitle, "成形期")
        XCTAssertEqual(model.identityLine, "阴天 · 学者")
        XCTAssertEqual(model.inviteCode, "ABCD2345")
        XCTAssertEqual(model.companionDayText, "相伴第 4 天")
        XCTAssertEqual(model.rows[0].subtitle, "希望被叫阿年")
        XCTAssertTrue(model.rows[0].showsIndicator)
        XCTAssertEqual(model.rows[1].subtitle, "面试题 · STAR 法则")
        XCTAssertEqual(model.rows[2].subtitle, "还差 3 天")
        XCTAssertEqual(model.rows[3].subtitle, "通知 · 播报 · 数据管理")
    }

    private var gmtCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func sampleSpirit(
        stage: SpiritStage = .whelp,
        scholarMarks: [String] = ["reader"]
    ) -> Spirit {
        Spirit(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            userID: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
            name: "雾生",
            egg: .warm,
            inviteCode: "ABCD2345",
            traits: TraitValues(closeness: 65, curiosity: 55, sharpness: 35, nocturnal: 40, stubborn: 40),
            vitals: VitalValues(hunger: 80, energy: 80, mood: 60, bond: 0),
            stage: stage,
            status: .home,
            scholarMarks: scholarMarks,
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
}
