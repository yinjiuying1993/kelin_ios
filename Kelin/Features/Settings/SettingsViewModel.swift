import Foundation

enum SettingsSheet: Equatable, Sendable {
    case rename
    case dnd
    case aiDisclosure
}

@MainActor
@Observable
final class SettingsViewModel {
    private(set) var spiritName: String
    private(set) var inviteCode: String
    private(set) var ttsOn: Bool
    private(set) var pushOn: Bool
    private(set) var visitOn: Bool
    private(set) var locationWeatherOn: Bool
    private(set) var remoteSearchOn: Bool
    private(set) var dndStart: String
    private(set) var dndEnd: String
    private(set) var friendCount: Int
    private(set) var copiedInviteCode = false
    private(set) var bannerMessage: String?
    private(set) var notificationPermissionDenied: Bool
    private(set) var locationPermissionDenied: Bool

    var draftName: String
    var draftDNDStart: Date
    var draftDNDEnd: Date
    var presentedSheet: SettingsSheet?
    var pendingDanger: SettingsDangerAction?
    var pendingPermission: PermissionKind?

    let spiritID: UUID
    let appVersion: String
    let isOffline: Bool
    let usesRemoteSettingsAPI: Bool
    private let settingsService: (any SettingsServiceProtocol)?
    private let memoryService: (any MemoryServiceProtocol)?
    private let socialService: (any SocialServiceProtocol)?
    private let clientIDs: P16P20ClientIDStore?
    private let accountUserID: UUID?
    private let onPatch: ((SessionPatch) -> Void)?
    private let onAccountDeleted: (() async -> Void)?
    private let onRefreshSnapshot: (() async throws -> Int)?
    private let onPushPreferenceChanged: ((Bool) async -> Void)?
    private let onFriendCount: ((Int) -> Void)?
    private var snapshotVersion: Int

    var spiritIDDisplay: String {
        SettingsPresentationRules.displaySpiritID(spiritID)
    }

    var dndDisplay: String {
        SettingsPresentationRules.formatDND(start: dndStart, end: dndEnd)
    }

    var effectivePushOn: Bool {
        pushOn && !notificationPermissionDenied
    }

    var effectiveLocationWeatherOn: Bool {
        locationWeatherOn && !locationPermissionDenied
    }

    var showsDangerConfirm: Bool {
        get { pendingDanger != nil }
        set {
            if !newValue {
                pendingDanger = nil
            }
        }
    }

    var showsPermissionHelp: Bool {
        get { pendingPermission != nil }
        set {
            if !newValue {
                pendingPermission = nil
            }
        }
    }

    init(
        spiritName: String,
        spiritID: UUID,
        inviteCode: String,
        preferences: SpiritPreferences,
        friendCount: Int,
        isOffline: Bool,
        usesRemoteSettingsAPI: Bool = false,
        notificationPermissionDenied: Bool = false,
        locationPermissionDenied: Bool = false,
        appVersion: String = SettingsDraftFixtures.appVersion,
        snapshotVersion: Int = 0,
        settingsService: (any SettingsServiceProtocol)? = nil,
        memoryService: (any MemoryServiceProtocol)? = nil,
        socialService: (any SocialServiceProtocol)? = nil,
        clientIDs: P16P20ClientIDStore? = nil,
        accountUserID: UUID? = nil,
        onPatch: ((SessionPatch) -> Void)? = nil,
        onAccountDeleted: (() async -> Void)? = nil,
        onRefreshSnapshot: (() async throws -> Int)? = nil,
        onPushPreferenceChanged: ((Bool) async -> Void)? = nil,
        onFriendCount: ((Int) -> Void)? = nil
    ) {
        let remote = usesRemoteSettingsAPI && settingsService != nil
        let resolvedName = spiritName.isEmpty && !remote
            ? SettingsDraftFixtures.sampleName
            : spiritName
        let resolvedInvite = inviteCode.isEmpty && !remote
            ? SettingsDraftFixtures.sampleInviteCode
            : inviteCode
        let resolvedStart = preferences.dndStart.isEmpty
            ? SettingsPresentationRules.defaultDNDStart
            : preferences.dndStart
        let resolvedEnd = preferences.dndEnd.isEmpty
            ? SettingsPresentationRules.defaultDNDEnd
            : preferences.dndEnd
        self.spiritName = resolvedName
        self.spiritID = spiritID
        self.inviteCode = resolvedInvite
        ttsOn = preferences.ttsOn
        pushOn = preferences.pushOn
        visitOn = preferences.visitOn
        locationWeatherOn = preferences.locationWeatherOn
        remoteSearchOn = preferences.remoteSearchOn
        dndStart = resolvedStart
        dndEnd = resolvedEnd
        self.friendCount = friendCount
        self.isOffline = isOffline
        self.usesRemoteSettingsAPI = usesRemoteSettingsAPI && settingsService != nil
        self.notificationPermissionDenied = notificationPermissionDenied
        self.locationPermissionDenied = locationPermissionDenied
        self.appVersion = appVersion
        self.snapshotVersion = snapshotVersion
        self.settingsService = settingsService
        self.memoryService = memoryService
        self.socialService = socialService
        self.clientIDs = clientIDs
        self.accountUserID = accountUserID
        self.onPatch = onPatch
        self.onAccountDeleted = onAccountDeleted
        self.onRefreshSnapshot = onRefreshSnapshot
        self.onPushPreferenceChanged = onPushPreferenceChanged
        self.onFriendCount = onFriendCount
        draftName = resolvedName
        draftDNDStart = SettingsPresentationRules.date(fromHHMM: resolvedStart)
        draftDNDEnd = SettingsPresentationRules.date(fromHHMM: resolvedEnd)
    }

    func copyInviteCode() {
        copiedInviteCode = true
        bannerMessage = String(localized: "邀请码已复制")
    }

    func refreshFriendCount() async {
        guard usesRemoteSettingsAPI, let socialService else { return }
        do {
            let friends = try await fetchAllFriends(using: socialService)
            friendCount = friends.count
            onFriendCount?(friends.count)
        } catch {
            KelinLog.api.error(
                "settings_friends_refresh_failed error_code=\((error as? AppError ?? .unknown(requestID: "")).diagnosticCode)"
            )
        }
    }

    func setTTSOn(_ enabled: Bool) {
        let previous = ttsOn
        ttsOn = enabled
        patch(
            key: P16P20ClientIDStore.settingsTTSKey,
            preferences: PreferencesPatchDTO(ttsOn: enabled),
            rollback: { self.ttsOn = previous }
        )
    }

    func setPushOn(_ enabled: Bool) {
        if enabled, notificationPermissionDenied {
            pendingPermission = .notifications
            return
        }
        let previous = pushOn
        pushOn = enabled
        patch(
            key: P16P20ClientIDStore.settingsPushKey,
            preferences: PreferencesPatchDTO(pushOn: enabled),
            rollback: { self.pushOn = previous },
            afterSuccess: { [weak self] in
                await self?.onPushPreferenceChanged?(enabled)
            }
        )
    }

    func setVisitOn(_ enabled: Bool) {
        let previous = visitOn
        visitOn = enabled
        patch(
            key: P16P20ClientIDStore.settingsVisitKey,
            preferences: PreferencesPatchDTO(visitOn: enabled),
            rollback: { self.visitOn = previous }
        )
    }

    func setLocationWeatherOn(_ enabled: Bool) {
        if enabled, locationPermissionDenied {
            pendingPermission = .location
            return
        }
        let previous = locationWeatherOn
        locationWeatherOn = enabled
        patch(
            key: P16P20ClientIDStore.settingsLocationKey,
            preferences: PreferencesPatchDTO(locationWeatherOn: enabled),
            rollback: { self.locationWeatherOn = previous }
        )
    }

    func setRemoteSearchOn(_ enabled: Bool) {
        let previous = remoteSearchOn
        remoteSearchOn = enabled
        patch(
            key: P16P20ClientIDStore.settingsSearchKey,
            preferences: PreferencesPatchDTO(remoteSearchOn: enabled),
            rollback: { self.remoteSearchOn = previous }
        )
    }

    func commitRename() {
        do {
            let name = try SettingsPresentationRules.validateName(draftName)
            let previous = spiritName
            spiritName = name
            presentedSheet = nil
            patch(key: P16P20ClientIDStore.settingsNameKey, name: name, rollback: { self.spiritName = previous })
        } catch {
            bannerMessage = String(localized: "名字还没写好")
        }
    }

    func commitDND() {
        let previousStart = dndStart
        let previousEnd = dndEnd
        dndStart = SettingsPresentationRules.hhmm(from: draftDNDStart)
        dndEnd = SettingsPresentationRules.hhmm(from: draftDNDEnd)
        presentedSheet = nil
        patch(
            key: P16P20ClientIDStore.settingsDNDKey,
            preferences: PreferencesPatchDTO(dndStart: dndStart, dndEnd: dndEnd),
            rollback: {
                self.dndStart = previousStart
                self.dndEnd = previousEnd
            }
        )
    }

    func confirmDanger() {
        let action = pendingDanger
        pendingDanger = nil
        switch action {
        case .clearAllMemories:
            Task { await clearAllMemories() }
        case .deleteAccount:
            Task { await deleteAccount() }
        case .none:
            break
        }
    }

    func previewPermissionClosed() {
        notificationPermissionDenied = true
        locationPermissionDenied = true
        pushOn = true
        locationWeatherOn = true
    }

    func previewCanvasDefaults() {
        spiritName = SettingsDraftFixtures.sampleName
        inviteCode = SettingsDraftFixtures.sampleInviteCode
        ttsOn = false
        pushOn = true
        visitOn = true
        locationWeatherOn = true
        remoteSearchOn = true
        dndStart = SettingsPresentationRules.defaultDNDStart
        dndEnd = SettingsPresentationRules.defaultDNDEnd
        friendCount = SettingsDraftFixtures.sampleFriendCount
        notificationPermissionDenied = false
        locationPermissionDenied = false
        draftName = spiritName
        draftDNDStart = SettingsPresentationRules.date(fromHHMM: dndStart)
        draftDNDEnd = SettingsPresentationRules.date(fromHHMM: dndEnd)
    }

    private func markLocalOnlyChange() {
        guard !usesRemoteSettingsAPI else { return }
        bannerMessage = String(localized: "设置接口尚未开通，这一页先按稿展示")
    }

    private func patch(
        key: String,
        name: String? = nil,
        preferences: PreferencesPatchDTO? = nil,
        rollback: @escaping () -> Void,
        afterSuccess: (() async -> Void)? = nil
    ) {
        guard usesRemoteSettingsAPI, let settingsService else {
            markLocalOnlyChange()
            return
        }
        Task {
            do {
                let clientID = try await stableClientID(for: key)
                let patch = try await sendPatch(
                    settingsService: settingsService,
                    expectedVersion: snapshotVersion,
                    name: name,
                    preferences: preferences,
                    clientID: clientID
                )
                snapshotVersion = patch.snapshotVersion
                onPatch?(patch)
                try? await forgetClientID(key)
                await afterSuccess?()
            } catch let error as AppError where error == .conflict {
                do {
                    snapshotVersion = try await onRefreshSnapshot?() ?? snapshotVersion
                    let clientID = try await stableClientID(for: key)
                    let patch = try await sendPatch(
                        settingsService: settingsService,
                        expectedVersion: snapshotVersion,
                        name: name,
                        preferences: preferences,
                        clientID: clientID
                    )
                    snapshotVersion = patch.snapshotVersion
                    onPatch?(patch)
                    try? await forgetClientID(key)
                    await afterSuccess?()
                } catch {
                    rollback()
                    bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
                }
            } catch {
                rollback()
                bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
            }
        }
    }

    private func sendPatch(
        settingsService: any SettingsServiceProtocol,
        expectedVersion: Int,
        name: String?,
        preferences: PreferencesPatchDTO?,
        clientID: UUID
    ) async throws -> SessionPatch {
        try await settingsService.patchSpirit(
            expectedVersion: expectedVersion,
            name: name,
            preferences: preferences,
            clientID: clientID
        )
    }

    private func clearAllMemories() async {
        guard usesRemoteSettingsAPI, let memoryService else {
            bannerMessage = String(localized: "设置接口尚未开通，记忆不会从这一页清除")
            return
        }
        do {
            let mutation = try await memoryService.clearAll(clientID: UUID())
            onPatch?(mutation.patch)
        } catch {
            bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
        }
    }

    private func deleteAccount() async {
        guard usesRemoteSettingsAPI, let settingsService else {
            bannerMessage = String(localized: "注销接口尚未开通，本地数据不会被清除")
            return
        }
        do {
            let clientID = try await stableClientID(for: P16P20ClientIDStore.settingsDeleteAccountKey)
            _ = try await settingsService.deleteAccount(clientID: clientID)
            await onAccountDeleted?()
        } catch {
            bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
        }
    }

    private func stableClientID(for key: String) async throws -> UUID {
        if let clientIDs, let accountUserID {
            return try await clientIDs.clientID(for: key, accountUserID: accountUserID)
        }
        return UUID()
    }

    private func forgetClientID(_ key: String) async throws {
        guard let clientIDs, let accountUserID else { return }
        try await clientIDs.forget(key: key, accountUserID: accountUserID)
    }

    private func fetchAllFriends(using socialService: any SocialServiceProtocol) async throws -> [Friend] {
        var cursor: String?
        var items: [Friend] = []
        var retriedCursor = false
        while items.count < 500 {
            do {
                let page = try await socialService.listFriends(cursor: cursor, limit: 30)
                items.append(contentsOf: page.items)
                if page.hasMore, let next = page.nextCursor, !next.isEmpty {
                    cursor = next
                } else {
                    break
                }
            } catch let error as AppError where error == .invalidCursor && !retriedCursor {
                retriedCursor = true
                cursor = nil
                items = []
            }
        }
        return items
    }
}
