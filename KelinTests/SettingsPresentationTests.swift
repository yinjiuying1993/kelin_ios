import XCTest
@testable import Kelin

final class SettingsPresentationTests: XCTestCase {
    func testCopyAndCanvasTokensMatchS11() {
        XCTAssertEqual(SettingsPresentationRules.screenTitle(), "设置")
        XCTAssertEqual(SettingsPresentationRules.spiritGroupTitle(), "精灵")
        XCTAssertEqual(SettingsPresentationRules.companionGroupTitle(), "陪伴")
        XCTAssertEqual(SettingsPresentationRules.socialGroupTitle(), "社交")
        XCTAssertEqual(SettingsPresentationRules.dataGroupTitle(), "数据")
        XCTAssertEqual(SettingsPresentationRules.aboutGroupTitle(), "关于")
        XCTAssertEqual(SettingsPresentationRules.renameTitle(), "改名")
        XCTAssertEqual(SettingsPresentationRules.ttsTitle(), "自动语音播报")
        XCTAssertEqual(SettingsPresentationRules.notificationTitle(), "通知")
        XCTAssertEqual(SettingsPresentationRules.dndTitle(), "勿扰时段")
        XCTAssertEqual(SettingsPresentationRules.locationWeatherTitle(), "定位天气")
        XCTAssertEqual(SettingsPresentationRules.remoteSearchTitle(), "联网查询")
        XCTAssertEqual(SettingsPresentationRules.visitTitle(), "允许来访")
        XCTAssertEqual(SettingsPresentationRules.friendsTitle(), "好友管理")
        XCTAssertEqual(SettingsPresentationRules.memoryCenterTitle(), "记忆中心")
        XCTAssertEqual(SettingsPresentationRules.clearAllTitle(), "清除全部记忆")
        XCTAssertEqual(SettingsPresentationRules.deleteAccountTitle(), "注销数据")
        XCTAssertEqual(SettingsPresentationRules.aiDisclosureTitle(), "它是人工智能")
        XCTAssertEqual(SettingsPresentationRules.versionTitle(), "当前版本")
        XCTAssertEqual(SettingsPresentationRules.footerCopy(), "相处，会在身上留下痕迹")
        XCTAssertEqual(SettingsPresentationRules.draftVersion, "V0.9.4")
        XCTAssertEqual(
            SettingsPresentationRules.displaySpiritID(SettingsDraftFixtures.sampleSpiritID),
            "KL-8f2c…4e91"
        )
        XCTAssertEqual(SettingsPresentationRules.formatDND(start: "23:00", end: "08:00"), "23:00 – 08:00")
        XCTAssertEqual(SettingsPresentationRules.confirmTitle(for: .clearAllMemories), "清除所有记忆？")
        XCTAssertEqual(SettingsPresentationRules.confirmMessage(for: .clearAllMemories), "口癖、偏好、见闻和知识都会消失。")
        XCTAssertEqual(SettingsPresentationRules.confirmAction(for: .clearAllMemories), "全部清除")
        XCTAssertEqual(SettingsPresentationRules.confirmTitle(for: .deleteAccount), "删除这只灵？")
        XCTAssertEqual(SettingsPresentationRules.confirmMessage(for: .deleteAccount), "所有记忆、消息和关系都会被删除。")
        XCTAssertEqual(SettingsPresentationRules.confirmAction(for: .deleteAccount), "删除数据")
    }

    func testNameValidationRejectsBlank() throws {
        XCTAssertEqual(try SettingsPresentationRules.validateName(" 雾生 "), "雾生")
        XCTAssertThrowsError(try SettingsPresentationRules.validateName("   "))
        XCTAssertThrowsError(try SettingsPresentationRules.validateName(String(repeating: "雾", count: 21)))
    }

    @MainActor
    func testLocalTogglesNeverEnableRemoteSettings() {
        let model = SettingsViewModel(
            spiritName: "雾生",
            spiritID: SettingsDraftFixtures.sampleSpiritID,
            inviteCode: "ABCD2345",
            preferences: SettingsDraftFixtures.defaultPreferences,
            friendCount: 2,
            isOffline: false
        )
        XCTAssertFalse(model.usesRemoteSettingsAPI)
        XCTAssertFalse(model.ttsOn)
        XCTAssertTrue(model.effectivePushOn)
        XCTAssertEqual(model.dndDisplay, "23:00 – 08:00")

        model.setTTSOn(true)
        XCTAssertTrue(model.ttsOn)
        XCTAssertEqual(model.bannerMessage, "设置接口尚未开通，这一页先按稿展示")
        XCTAssertFalse(model.usesRemoteSettingsAPI)
    }

    @MainActor
    func testDeniedSystemPermissionDoesNotAppearAvailable() {
        let model = SettingsViewModel(
            spiritName: "雾生",
            spiritID: SettingsDraftFixtures.sampleSpiritID,
            inviteCode: "ABCD2345",
            preferences: SettingsDraftFixtures.defaultPreferences,
            friendCount: 2,
            isOffline: false,
            notificationPermissionDenied: true,
            locationPermissionDenied: true
        )
        XCTAssertFalse(model.effectivePushOn)
        XCTAssertFalse(model.effectiveLocationWeatherOn)

        model.setPushOn(true)
        XCTAssertEqual(model.pendingPermission, .notifications)
        XCTAssertFalse(model.effectivePushOn)

        model.setLocationWeatherOn(true)
        XCTAssertEqual(model.pendingPermission, .location)
        XCTAssertFalse(model.effectiveLocationWeatherOn)
    }

    @MainActor
    func testDangerConfirmStaysLocalAndDoesNotClear() {
        let model = SettingsViewModel(
            spiritName: "雾生",
            spiritID: SettingsDraftFixtures.sampleSpiritID,
            inviteCode: "ABCD2345",
            preferences: SettingsDraftFixtures.defaultPreferences,
            friendCount: 2,
            isOffline: false
        )
        model.pendingDanger = .clearAllMemories
        model.confirmDanger()
        XCTAssertEqual(model.bannerMessage, "设置接口尚未开通，记忆不会从这一页清除")
        XCTAssertNil(model.pendingDanger)

        model.pendingDanger = .deleteAccount
        model.confirmDanger()
        XCTAssertEqual(model.bannerMessage, "注销接口尚未开通，本地数据不会被清除")
        XCTAssertFalse(model.usesRemoteSettingsAPI)
    }
}
