import Foundation

enum SettingsDraftFixtures {
    static let sampleName = String(localized: "雾生")
    static let sampleInviteCode = SettingsPresentationRules.sampleInviteCode
    static let sampleSpiritID = UUID(uuidString: "8F2C0000-0000-4000-8000-000000004E91")!
    static let sampleFriendCount = 2
    static let appVersion = SettingsPresentationRules.draftVersion

    static let defaultPreferences = SpiritPreferences(
        ttsOn: false,
        pushOn: true,
        visitOn: true,
        dndStart: SettingsPresentationRules.defaultDNDStart,
        dndEnd: SettingsPresentationRules.defaultDNDEnd,
        timezone: "Asia/Shanghai",
        defaultCity: nil,
        locationWeatherOn: true,
        remoteSearchOn: true
    )
}
