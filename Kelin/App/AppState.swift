import Foundation

@MainActor
@Observable
final class AppState {
    let sessionStore: SessionStore

    private(set) var phase: AppPhase = .launching
    private(set) var isOffline = false
    private(set) var isShowingCachedSnapshot = false
    private(set) var lastSuccessfulBootstrapAt: Date?
    private(set) var lastKnownFriendCount = 0
    private(set) var pendingConsents: CreateSpiritConsents?
    private(set) var agreementError: AppError?
    private(set) var isSubmittingAgreement = false
    private(set) var hatchError: AppError?
    private(set) var isSubmittingHatch = false
    private(set) var onboardingMessages: [OnboardingMessage] = []
    private(set) var isSendingOnboardingMessage = false
    private(set) var onboardingChatError: AppError?
    private(set) var onboardingChatServiceUsesStub = false
    private(set) var isHatching = false
    private(set) var onboardingCompleteError: AppError?
    private(set) var isCompletingOnboarding = false
    let usesRemoteAPI: Bool
    let apiBaseURL: URL?
    private let healthLiveProbe: (@Sendable () async throws -> String)?

    var hasCompletedOnboardingConversation: Bool {
        (sessionStore.snapshot?.onboarding.step ?? 0) >= OnboardingConversationDefaults.totalSteps
    }

    private let auth: any AuthServiceProtocol
    private let localStore: LocalStore
    private let bootstrapService: any BootstrapServiceProtocol
    private let agreementGate: any AgreementGateServiceProtocol
    private let hatchService: any HatchServiceProtocol
    private let onboardingChatService: any OnboardingChatServiceProtocol
    private let onboardingCompleteService: any OnboardingCompleteServiceProtocol
    private let chatService: any ChatServiceProtocol
    private let messagesService: any MessagesServiceProtocol
    private let extractService: any ExtractServiceProtocol
    private let memoryService: any MemoryServiceProtocol
    private let feedService: any FeedServiceProtocol
    private let speechService: any SpeechServiceProtocol
    private let pactService: any PactServiceProtocol
    private let socialService: any SocialServiceProtocol
    private let deviceService: any DeviceServiceProtocol
    private let reportService: any ReportServiceProtocol
    private let settingsService: any SettingsServiceProtocol
    private let bootstrapCoordinator: BootstrapCoordinator
    private let syncCoordinator: SyncCoordinator?
    private let hatchAnimationDuration: Duration

    private var launchTask: Task<Void, Never>?
    private var completeOnboardingTask: Task<Void, Never>?
    private var activeAccountUserID: UUID?
    private var pendingSpiritClientID: UUID?
    private var pendingOnboardingClientMessageID: UUID?
    private var pendingOnboardingChatContent: String?
    private var pendingOnboardingCompleteClientID: UUID?

    init(
        auth: any AuthServiceProtocol,
        localStore: LocalStore,
        bootstrapService: any BootstrapServiceProtocol,
        agreementGate: any AgreementGateServiceProtocol = MockAgreementGateService(),
        hatchService: any HatchServiceProtocol = MockHatchService(),
        onboardingChatService: any OnboardingChatServiceProtocol = MockOnboardingChatService(),
        onboardingCompleteService: any OnboardingCompleteServiceProtocol = MockOnboardingCompleteService(),
        chatService: any ChatServiceProtocol = MockChatService(),
        messagesService: any MessagesServiceProtocol = MockMessagesService(),
        extractService: any ExtractServiceProtocol = MockExtractService(),
        memoryService: any MemoryServiceProtocol = MockMemoryService(),
        feedService: any FeedServiceProtocol = MockFeedService(),
        speechService: any SpeechServiceProtocol = MockSpeechService(),
        pactService: any PactServiceProtocol = MockPactService(),
        socialService: any SocialServiceProtocol = MockSocialService(),
        deviceService: any DeviceServiceProtocol = MockDeviceService(),
        reportService: any ReportServiceProtocol = MockReportService(),
        settingsService: any SettingsServiceProtocol = MockSettingsService(),
        sessionStore: SessionStore = SessionStore(),
        bootstrapCoordinator: BootstrapCoordinator = BootstrapCoordinator(),
        syncCoordinator: SyncCoordinator? = nil,
        hatchAnimationDuration: Duration = .milliseconds(1_000),
        usesRemoteAPI: Bool = false,
        apiBaseURL: URL? = nil,
        healthLiveProbe: (@Sendable () async throws -> String)? = nil
    ) {
        self.auth = auth
        self.localStore = localStore
        self.bootstrapService = bootstrapService
        self.agreementGate = agreementGate
        self.hatchService = hatchService
        self.onboardingChatService = onboardingChatService
        self.onboardingCompleteService = onboardingCompleteService
        self.chatService = chatService
        self.messagesService = messagesService
        self.extractService = extractService
        self.memoryService = memoryService
        self.feedService = feedService
        self.speechService = speechService
        self.pactService = pactService
        self.socialService = socialService
        self.deviceService = deviceService
        self.reportService = reportService
        self.settingsService = settingsService
        self.sessionStore = sessionStore
        self.bootstrapCoordinator = bootstrapCoordinator
        self.syncCoordinator = syncCoordinator
        self.hatchAnimationDuration = hatchAnimationDuration
        self.usesRemoteAPI = usesRemoteAPI
        self.apiBaseURL = apiBaseURL
        self.healthLiveProbe = healthLiveProbe
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        let spirit = sessionStore.snapshot?.spirit
        return SettingsViewModel(
            spiritName: spirit?.name ?? SettingsDraftFixtures.sampleName,
            spiritID: spirit?.id ?? SettingsDraftFixtures.sampleSpiritID,
            inviteCode: spirit?.inviteCode ?? SettingsDraftFixtures.sampleInviteCode,
            preferences: spirit?.preferences ?? SettingsDraftFixtures.defaultPreferences,
            friendCount: lastKnownFriendCount,
            isOffline: isOffline,
            usesRemoteSettingsAPI: usesRemoteAPI && P16P20ContractManifest.liveHasSpiritPatch,
            snapshotVersion: sessionStore.snapshot?.snapshotVersion ?? 0,
            settingsService: settingsService,
            memoryService: memoryService,
            socialService: socialService,
            clientIDs: P16P20ClientIDStore(localStore: localStore),
            accountUserID: activeAccountUserID,
            onPatch: { [weak self] patch in
                self?.applyAuthoritativePatch(patch)
            },
            onAccountDeleted: { [weak self] in
                await self?.handleAccountDeleted()
            },
            onRefreshSnapshot: { [weak self] in
                guard let self else { return 0 }
                return try await self.refreshSnapshotVersionForSettings()
            },
            onPushPreferenceChanged: { [weak self] enabled in
                await self?.registerDeviceIfPossible(enabled: enabled)
            },
            onFriendCount: { [weak self] count in
                self?.lastKnownFriendCount = count
            }
        )
    }

    func makeSocialViewModel() -> SocialViewModel {
        SocialViewModel(
            inviteCode: sessionStore.snapshot?.spirit?.inviteCode ?? SocialPresentationRules.sampleInviteCode,
            isOffline: isOffline,
            visitEnabled: sessionStore.snapshot?.spirit?.preferences.visitOn ?? true,
            usesRemoteSocialAPI: usesRemoteAPI && P16P20ContractManifest.liveHasFriendsRoutes,
            socialService: socialService,
            settingsService: settingsService,
            localStore: localStore,
            clientIDs: P16P20ClientIDStore(localStore: localStore),
            accountUserID: activeAccountUserID,
            snapshotVersion: sessionStore.snapshot?.snapshotVersion ?? 0,
            onPatch: { [weak self] patch in
                self?.applyAuthoritativePatch(patch)
            },
            onFriendCount: { [weak self] count in
                self?.lastKnownFriendCount = count
            }
        )
    }

    func makeReportViewModel() -> ReportViewModel {
        ReportViewModel(
            snapshot: sessionStore.snapshot?.report ?? ReportSnapshot(
                status: .locked,
                reportID: nil,
                eligibility: ReportEligibility(
                    isEligible: false,
                    eligibleAt: Date(),
                    daysRemaining: 7,
                    requiredDialogueRounds: 10,
                    completedDialogueRounds: 0,
                    dialogueRoundsRemaining: 10
                )
            ),
            spiritName: sessionStore.snapshot?.spirit?.name ?? String(localized: "雾生"),
            isOffline: isOffline,
            usesRemoteReportAPI: usesRemoteAPI && P16P20ContractManifest.liveHasReportRoutes,
            reportService: reportService,
            clientIDs: P16P20ClientIDStore(localStore: localStore),
            accountUserID: activeAccountUserID,
            onPatch: { [weak self] patch in
                self?.applyAuthoritativePatch(patch)
            },
            onSnapshot: { [weak self] report in
                self?.sessionStore.replaceReport(report)
            }
        )
    }

    func makePactViewModel() -> PactViewModel {
        PactViewModel(
            spiritName: sessionStore.snapshot?.spirit?.name ?? String(localized: "雾生"),
            isOffline: isOffline,
            activePact: sessionStore.snapshot?.activePact,
            usesRemotePactAPI: usesRemoteAPI,
            questions: [],
            pactService: pactService,
            queueStore: PactAnswerQueueStore(localStore: localStore),
            clientIDs: PactClientIDStore(localStore: localStore),
            accountUserID: activeAccountUserID,
            notesMemoryID: sessionStore.snapshot?.latestMemories.first(where: {
                $0.type == "knowledge" && $0.status == "active"
            })?.id,
            serverTime: sessionStore.snapshot?.serverTime,
            timeZoneIdentifier: sessionStore.snapshot?.spirit?.preferences.timezone,
            onPatch: { [weak self] patch in
                self?.applyAuthoritativePatch(patch)
            }
        )
    }

    func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(
            quotas: sessionStore.snapshot?.quotas ?? [],
            isOffline: isOffline,
            spiritVersion: sessionStore.snapshot?.spirit?.version ?? 1,
            feedService: feedService,
            clientIDs: FeedClientIDStore(localStore: localStore),
            accountUserID: activeAccountUserID,
            onPatch: { [weak self] patch in
                self?.applyAuthoritativePatch(patch)
            }
        )
    }

    func makeMemoryViewModel() -> MemoryViewModel {
        MemoryViewModel(
            memories: [],
            spiritName: sessionStore.snapshot?.spirit?.name ?? String(localized: "它"),
            isOffline: isOffline,
            memoryService: memoryService,
            localStore: localStore,
            clientIDs: MemoryClientIDStore(localStore: localStore),
            accountUserID: activeAccountUserID,
            onPatch: { [weak self] patch in
                self?.applyAuthoritativePatch(patch)
            }
        )
    }

    func makeChatViewModel() -> ChatViewModel? {
        guard let activeAccountUserID else { return nil }

        return ChatViewModel(
            chatService: chatService,
            historyCache: ChatHistoryCache(localStore: localStore),
            localStore: localStore,
            accountUserID: activeAccountUserID,
            speechService: speechService,
            messagesService: messagesService,
            extractService: extractService,
            extractClientIDs: ExtractClientIDStore(localStore: localStore),
            syncCoordinator: syncCoordinator,
            makeContext: { [weak self] in
                ChatSendContext.make(weather: self?.sessionStore.snapshot?.room?.weather)
            },
            onPatch: { [weak self] patch in
                guard let self else { return }
                self.applyAuthoritativePatch(patch)
            }
        )
    }

    func failBeforeLaunch(_ error: AppError) {
        KelinLog.launch.error("fail_before_launch error_code=\(error.diagnosticCode)")
        phase = .recoverableError(error)
    }

    func discardLocalCacheAndReload() async {
        KelinLog.launch.info(
            "discard_cache user=\(self.activeAccountUserID.map(KelinLog.shortID) ?? "nil")"
        )
        if let activeAccountUserID {
            try? await localStore.clearAccount(accountUserID: activeAccountUserID)
            try? await clearOnboardingConversationCache(accountUserID: activeAccountUserID)
        }

        sessionStore.clear()
        onboardingMessages = []
        pendingConsents = nil
        pendingSpiritClientID = nil
        pendingOnboardingClientMessageID = nil
        pendingOnboardingChatContent = nil
        pendingOnboardingCompleteClientID = nil
        isOffline = false
        isShowingCachedSnapshot = false
        lastSuccessfulBootstrapAt = nil
        beginLaunch()
    }

    func handleAccountDeleted() async {
        KelinLog.launch.info("account_deleted_clear_local")
        if let activeAccountUserID {
            try? await localStore.clearAccount(accountUserID: activeAccountUserID)
        }
        sessionStore.clear()
        try? await auth.signOut()
        onboardingMessages = []
        pendingConsents = nil
        isOffline = false
        isShowingCachedSnapshot = false
        lastSuccessfulBootstrapAt = nil
        lastKnownFriendCount = 0
        beginLaunch()
    }

    func refreshRoomIfReady(now: Date = Date()) async {
        guard phase == .ready, usesRemoteAPI, sessionStore.snapshot != nil else {
            return
        }

        guard sessionStore.needsBootstrapRefresh
            || RoomRefreshRules.shouldRefresh(lastRefreshAt: lastSuccessfulBootstrapAt, now: now) else {
            return
        }

        await refreshAuthoritativeSnapshotIfRemote()
        await registerDeviceIfPossible()
    }

    func beginLaunch() {
        launchTask?.cancel()
        launchTask = Task { [weak self] in
            await self?.performLaunch()
        }
    }

    func retryFromError() {
        beginLaunch()
    }

    func clearAgreementError() {
        agreementError = nil
    }

    func submitAgreement(
        aiDisclosureAccepted: Bool,
        hasViewedUserTerms: Bool,
        hasViewedDataNotice: Bool
    ) async {
        guard aiDisclosureAccepted, !isSubmittingAgreement else {
            return
        }

        agreementError = nil
        isSubmittingAgreement = true
        defer { isSubmittingAgreement = false }

        let consents = CreateSpiritConsents(
            aiDisclosure: .init(
                documentVersion: ConsentDocuments.currentVersion,
                explicitlyAccepted: true
            ),
            dataNotice: .init(
                documentVersion: ConsentDocuments.currentVersion,
                displayed: hasViewedDataNotice
            ),
            userTerms: .init(
                documentVersion: ConsentDocuments.currentVersion,
                displayed: hasViewedUserTerms
            )
        )

        do {
            try await agreementGate.acknowledgeAgreement(consents: consents)
            pendingConsents = consents
            phase = .needsEggSelection
            KelinLog.onboarding.info("agreement_ok phase=\(self.phase.diagnosticName)")
        } catch let error as AppError {
            agreementError = error
            logOnboardingError("agreement_failed", error)
        } catch {
            agreementError = .unknown(requestID: "")
            logOnboardingError("agreement_failed", agreementError!)
        }
    }

    func clearHatchError() {
        hatchError = nil
    }

    func returnToAgreement() {
        hatchError = nil
        phase = .needsAgreement
    }

    func returnToEggSelection() {
        onboardingChatError = nil
        phase = .needsEggSelection
    }

    func clearOnboardingChatError() {
        onboardingChatError = nil
    }

    var lastOnboardingDraft: String? {
        pendingOnboardingChatContent
    }

    func retryOnboardingChat() async {
        guard let content = pendingOnboardingChatContent, !content.isEmpty else {
            return
        }
        let retryClient = pendingOnboardingClientMessageID.map(KelinLog.shortID) ?? "nil"
        KelinLog.onboarding.info("chat_retry client=\(retryClient)")
        onboardingChatError = nil
        await sendOnboardingMessage(content: content)
    }

    func clearOnboardingCompleteError() {
        onboardingCompleteError = nil
    }

    func retryOnboardingComplete() {
        scheduleOnboardingCompleteIfNeeded()
    }

    func sendOnboardingMessage(content: String) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmed.isEmpty,
            !isSendingOnboardingMessage,
            !hasCompletedOnboardingConversation,
            case .needsFirstConversation = phase
        else {
            return
        }

        onboardingChatError = nil
        isSendingOnboardingMessage = true
        defer { isSendingOnboardingMessage = false }

        let clientMessageID = nextOnboardingClientMessageID(for: trimmed)
        await persistStableIDsIfPossible()

        let completedRounds = sessionStore.snapshot?.onboarding.step ?? 0

        KelinLog.onboarding.info(
            "chat_request onboarding=true source=onboarding client=\(KelinLog.shortID(clientMessageID)) rounds=\(completedRounds)/\(OnboardingConversationDefaults.totalSteps)"
        )

        do {
            let result = try await sendOnboardingTurn(
                clientMessageID: clientMessageID,
                content: trimmed,
                completedRounds: completedRounds
            )
            try await acceptOnboardingTurn(result)
        } catch let error as AppError {
            if await recoverFromAuthoritativeError(error) {
                return
            }
            onboardingChatError = error
            logOnboardingError("chat_failed", error)
        } catch {
            onboardingChatError = .unknown(requestID: "")
            logOnboardingError("chat_failed", onboardingChatError!)
        }
    }

    private func sendOnboardingTurn(
        clientMessageID: UUID,
        content: String,
        completedRounds: Int
    ) async throws -> OnboardingChatResult {
        try await onboardingChatService.sendOnboardingMessage(
            clientMessageID: clientMessageID,
            content: content,
            completedRounds: completedRounds
        )
    }

    private func acceptOnboardingTurn(_ result: OnboardingChatResult) async throws {
        onboardingMessages.append(result.userMessage)
        onboardingMessages.append(result.spiritMessage)
        onboardingChatServiceUsesStub = result.usesStubProvider
        pendingOnboardingClientMessageID = nil
        pendingOnboardingChatContent = nil
        await persistStableIDsIfPossible()

        try await applyOnboardingChatResult(result)
        try await persistOnboardingMessages()
        if let snapshot = sessionStore.snapshot {
            phase = resolvePhase(from: snapshot)
        }
        KelinLog.onboarding.info(
            "chat_ok client=\(KelinLog.shortID(result.userMessage.id)) rounds=\(result.completedRounds)/\(OnboardingConversationDefaults.totalSteps) snapshot=\(result.snapshotVersion) stub=\(result.usesStubProvider) phase=\(self.phase.diagnosticName)"
        )

        if result.completedRounds >= OnboardingConversationDefaults.totalSteps {
            scheduleOnboardingCompleteIfNeeded()
        }
    }

    private func applyOnboardingChatResult(_ result: OnboardingChatResult) async throws {
        guard let base = sessionStore.snapshot else {
            throw AppError.decoding
        }

        let snapshot = BootstrapSnapshot(
            schemaVersion: base.schemaVersion,
            snapshotVersion: result.snapshotVersion,
            apiVersion: base.apiVersion,
            spirit: result.spirit ?? base.spirit,
            room: base.room,
            onboarding: OnboardingState(
                required: true,
                step: result.completedRounds,
                totalSteps: OnboardingConversationDefaults.totalSteps,
                completedAt: nil
            ),
            latestMemories: base.latestMemories,
            unreadPostcards: base.unreadPostcards,
            activePact: base.activePact,
            report: base.report,
            quotas: base.quotas,
            featureFlags: base.featureFlags,
            serverTime: base.serverTime
        )

        sessionStore.replace(with: snapshot)

        if let activeAccountUserID {
            try await persistSnapshot(snapshot, accountUserID: activeAccountUserID)
        }
    }

    func createSpirit(selectedOption: EggSelectionOption) async {
        guard let consents = pendingConsents, !isSubmittingHatch else {
            return
        }

        guard
            consents.aiDisclosure.explicitlyAccepted,
            consents.dataNotice.displayed,
            consents.userTerms.displayed
        else {
            hatchError = .invalidInput
            KelinLog.onboarding.error("create_spirit_failed error_code=INVALID_INPUT details_keys=consents.displayed")
            return
        }

        hatchError = nil
        isSubmittingHatch = true
        defer { isSubmittingHatch = false }

        if pendingSpiritClientID == nil {
            pendingSpiritClientID = UUID()
        }
        await persistStableIDsIfPossible()

        let request = CreateSpiritRequest(
            clientID: pendingSpiritClientID!,
            egg: selectedOption.eggType,
            name: HatchDefaults.placeholderSpiritName,
            consents: consents
        )

        do {
            let result = try await hatchService.createSpirit(request)
            try await applyCreateSpiritResult(result)
            await refreshAuthoritativeSnapshotIfRemote()
            pendingSpiritClientID = nil
            onboardingMessages = []
            await persistStableIDsIfPossible()
            if let activeAccountUserID {
                try await clearOnboardingConversationCache(accountUserID: activeAccountUserID)
            }
            if let snapshot = sessionStore.snapshot {
                phase = resolvePhase(from: snapshot)
            }
            KelinLog.onboarding.info(
                "create_spirit_ok client=\(KelinLog.shortID(request.clientID)) egg=\(request.egg.rawValue) spirit=\(KelinLog.shortID(result.spirit.id)) version=\(result.spirit.version) snapshot=\(result.snapshotVersion) phase=\(self.phase.diagnosticName)"
            )
        } catch let error as AppError {
            if await recoverFromAuthoritativeError(error) {
                return
            }
            hatchError = error
            logOnboardingError("create_spirit_failed", error)
        } catch {
            hatchError = .unknown(requestID: "")
            logOnboardingError("create_spirit_failed", hatchError!)
        }
    }

    private func applyCreateSpiritResult(_ result: CreateSpiritResult) async throws {
        guard let base = sessionStore.snapshot else {
            throw AppError.decoding
        }

        let snapshot = BootstrapSnapshot(
            schemaVersion: base.schemaVersion,
            snapshotVersion: result.snapshotVersion,
            apiVersion: base.apiVersion,
            spirit: result.spirit,
            room: result.room ?? base.room,
            onboarding: result.onboarding,
            latestMemories: base.latestMemories,
            unreadPostcards: base.unreadPostcards,
            activePact: base.activePact,
            report: base.report,
            quotas: base.quotas,
            featureFlags: base.featureFlags,
            serverTime: base.serverTime
        )

        sessionStore.replace(with: snapshot)

        if let activeAccountUserID {
            try await persistSnapshot(snapshot, accountUserID: activeAccountUserID)
        }
    }

    private func performLaunch() async {
        phase = .launching
        isOffline = false
        isShowingCachedSnapshot = false
        activeAccountUserID = nil
        KelinLog.launch.info(
            "begin remote_api=\(self.usesRemoteAPI) base=\(self.apiBaseURL?.absoluteString ?? "nil")"
        )

        do {
            try Task.checkCancellation()
            await probeHealthLiveIfNeeded()
            phase = .restoringSession

            let session = try await resolveSession()
            activeAccountUserID = session.userID
            KelinLog.launch.info(
                "session_ready user=\(KelinLog.shortID(session.userID))"
            )

            let hadCachedSnapshot = try await loadCachedSnapshot(for: session.userID)

            if let syncCoordinator {
                await syncCoordinator.setAccountUserID(session.userID)
                Task {
                    await syncCoordinator.resumePendingOperations()
                }
            }

            if !hadCachedSnapshot {
                phase = .requestingBootstrap
            }

            let cachedSnapshot = sessionStore.snapshot
            let freshSnapshot = try await bootstrapCoordinator.fetch(using: bootstrapService)
            let mergedSnapshot = mergeBootstrapSnapshots(cached: cachedSnapshot, fresh: freshSnapshot)
            sessionStore.replace(with: mergedSnapshot)
            try await persistSnapshot(mergedSnapshot, accountUserID: session.userID)
            try await restoreOnboardingConversationIfNeeded(for: session.userID, snapshot: mergedSnapshot)

            isShowingCachedSnapshot = false
            isOffline = false
            lastSuccessfulBootstrapAt = Date()
            phase = resolvePhase(from: mergedSnapshot)
            KelinLog.launch.info(
                "bootstrap_ok \(KelinLog.snapshotSummary(mergedSnapshot)) phase=\(self.phase.diagnosticName)"
            )
            await restoreStableIDs(for: session.userID, snapshot: mergedSnapshot)
            scheduleOnboardingCompleteIfNeeded()
            await registerDeviceIfPossible()
        } catch is CancellationError {
            return
        } catch let error as AppError {
            handleLaunchFailure(error)
        } catch {
            handleLaunchFailure(.unknown(requestID: ""))
        }
    }

    private func resolveSession() async throws -> AuthSession {
        if let session = try await auth.restoreSession() {
            return session
        }

        try Task.checkCancellation()
        phase = .signingInAnonymously
        KelinLog.auth.info("sign_in_required")
        return try await auth.signInAnonymously()
    }

    @discardableResult
    private func loadCachedSnapshot(for accountUserID: UUID) async throws -> Bool {
        guard let cached = try await localStore.fetchBootstrap(accountUserID: accountUserID) else {
            return false
        }

        guard cached.accountUserID == accountUserID else {
            return false
        }

        let snapshot = try BootstrapCacheCodec.decode(cached.payloadData)
        sessionStore.replace(with: snapshot)
        isShowingCachedSnapshot = true
        phase = resolvePhase(from: snapshot)
        KelinLog.launch.info(
            "cache_hit \(KelinLog.snapshotSummary(snapshot)) phase=\(self.phase.diagnosticName)"
        )
        return true
    }

    private func persistSnapshot(_ snapshot: BootstrapSnapshot, accountUserID: UUID) async throws {
        let record = CachedBootstrapRecord(
            accountUserID: accountUserID,
            payloadData: try BootstrapCacheCodec.encode(snapshot),
            snapshotVersion: snapshot.snapshotVersion,
            updatedAt: snapshot.serverTime
        )
        try await localStore.upsertBootstrap(record)
    }

    private func handleLaunchFailure(_ error: AppError) {
        if sessionStore.snapshot != nil {
            isOffline = true
            if let snapshot = sessionStore.snapshot {
                phase = resolvePhase(from: snapshot)
            }
            KelinLog.launch.error(
                "launch_failed error_code=\(error.diagnosticCode) offline_cache=true phase=\(self.phase.diagnosticName)"
            )
            return
        }

        phase = .recoverableError(error)
        KelinLog.launch.error(
            "launch_failed error_code=\(error.diagnosticCode) offline_cache=false phase=\(self.phase.diagnosticName)"
        )
    }

    private func resolvePhase(from snapshot: BootstrapSnapshot) -> AppPhase {
        if snapshot.spirit == nil {
            return .needsAgreement
        }

        if snapshot.onboarding.required, snapshot.onboarding.completedAt == nil {
            if snapshot.onboarding.step == 0 {
                return .needsFirstConversation(step: 1)
            }

            let completed = snapshot.onboarding.step
            if completed >= OnboardingConversationDefaults.totalSteps {
                return .needsFirstConversation(step: OnboardingConversationDefaults.totalSteps)
            }
            return .needsFirstConversation(step: completed + 1)
        }

        return .ready
    }

    private func scheduleOnboardingCompleteIfNeeded() {
        guard
            hasCompletedOnboardingConversation,
            sessionStore.snapshot?.onboarding.completedAt == nil,
            !isCompletingOnboarding,
            completeOnboardingTask == nil
        else {
            return
        }

        completeOnboardingTask = Task { [weak self] in
            await self?.performOnboardingComplete()
            self?.completeOnboardingTask = nil
        }
    }

    private func performOnboardingComplete() async {
        guard
            let snapshot = sessionStore.snapshot,
            let spirit = snapshot.spirit,
            hasCompletedOnboardingConversation,
            snapshot.onboarding.completedAt == nil
        else {
            return
        }

        if pendingOnboardingCompleteClientID == nil {
            pendingOnboardingCompleteClientID = UUID()
        }
        await persistStableIDsIfPossible()

        onboardingCompleteError = nil
        isCompletingOnboarding = true
        isHatching = true
        defer {
            isCompletingOnboarding = false
            isHatching = false
        }

        do {
            if hatchAnimationDuration > .zero {
                try await Task.sleep(for: hatchAnimationDuration)
            }
            try Task.checkCancellation()

            let completeClientID = pendingOnboardingCompleteClientID!
            let result = try await onboardingCompleteService.completeOnboarding(
                clientID: completeClientID,
                expectedSpiritVersion: spirit.version
            )

            try await applyOnboardingCompleteResult(result)
            await refreshAuthoritativeSnapshotIfRemote()
            pendingOnboardingCompleteClientID = nil
            await persistStableIDsIfPossible()

            if let activeAccountUserID {
                try await clearOnboardingConversationCache(accountUserID: activeAccountUserID)
            }

            if let snapshot = sessionStore.snapshot {
                phase = resolvePhase(from: snapshot)
            } else {
                phase = .ready
            }
            KelinLog.onboarding.info(
                "complete_ok client=\(KelinLog.shortID(completeClientID)) expected_version=\(spirit.version) snapshot=\(result.snapshotVersion) phase=\(self.phase.diagnosticName)"
            )
        } catch is CancellationError {
            return
        } catch let error as AppError {
            if await recoverFromAuthoritativeError(error) {
                return
            }
            onboardingCompleteError = error
            logOnboardingError("complete_failed", error)
        } catch {
            onboardingCompleteError = .unknown(requestID: "")
            logOnboardingError("complete_failed", onboardingCompleteError!)
        }
    }

    private func applyOnboardingCompleteResult(_ result: OnboardingCompleteResult) async throws {
        guard let base = sessionStore.snapshot else {
            throw AppError.decoding
        }

        let snapshot = BootstrapSnapshot(
            schemaVersion: base.schemaVersion,
            snapshotVersion: result.snapshotVersion,
            apiVersion: base.apiVersion,
            spirit: base.spirit,
            room: result.room ?? base.room,
            onboarding: result.onboarding,
            latestMemories: base.latestMemories,
            unreadPostcards: base.unreadPostcards,
            activePact: base.activePact,
            report: base.report,
            quotas: base.quotas,
            featureFlags: base.featureFlags,
            serverTime: base.serverTime
        )

        sessionStore.replace(with: snapshot)

        if let activeAccountUserID {
            try await persistSnapshot(snapshot, accountUserID: activeAccountUserID)
        }
    }

    private func mergeBootstrapSnapshots(
        cached: BootstrapSnapshot?,
        fresh: BootstrapSnapshot
    ) -> BootstrapSnapshot {
        guard
            let cached,
            let cachedSpirit = cached.spirit,
            cached.onboarding.required,
            cached.onboarding.completedAt == nil
        else {
            guard let cached else {
                return fresh
            }
            return BootstrapSnapshot(
                schemaVersion: fresh.schemaVersion,
                snapshotVersion: fresh.snapshotVersion,
                apiVersion: fresh.apiVersion,
                spirit: fresh.spirit,
                room: fresh.room,
                onboarding: fresh.onboarding,
                latestMemories: fresh.latestMemories,
                unreadPostcards: fresh.unreadPostcards,
                activePact: fresh.activePact ?? cached.activePact,
                report: fresh.report,
                quotas: fresh.quotas,
                featureFlags: fresh.featureFlags,
                serverTime: fresh.serverTime
            )
        }

        let mergedStep = max(cached.onboarding.step, fresh.onboarding.step)
        let spirit: Spirit? = {
            if let freshSpirit = fresh.spirit, freshSpirit.id == cachedSpirit.id {
                return freshSpirit
            }
            return cachedSpirit
        }()

        return BootstrapSnapshot(
            schemaVersion: fresh.schemaVersion,
            snapshotVersion: max(cached.snapshotVersion, fresh.snapshotVersion),
            apiVersion: fresh.apiVersion,
            spirit: spirit,
            room: fresh.room ?? cached.room,
            onboarding: OnboardingState(
                required: fresh.onboarding.completedAt == nil,
                step: mergedStep,
                totalSteps: max(cached.onboarding.totalSteps, fresh.onboarding.totalSteps),
                completedAt: fresh.onboarding.completedAt ?? cached.onboarding.completedAt
            ),
            latestMemories: fresh.latestMemories.isEmpty ? cached.latestMemories : fresh.latestMemories,
            unreadPostcards: fresh.unreadPostcards.isEmpty ? cached.unreadPostcards : fresh.unreadPostcards,
            activePact: fresh.activePact ?? cached.activePact,
            report: fresh.report,
            quotas: fresh.quotas.isEmpty ? cached.quotas : fresh.quotas,
            featureFlags: fresh.featureFlags,
            serverTime: fresh.serverTime
        )
    }

    private func restoreOnboardingConversationIfNeeded(
        for accountUserID: UUID,
        snapshot: BootstrapSnapshot
    ) async throws {
        guard snapshot.spirit != nil, snapshot.onboarding.completedAt == nil else {
            onboardingMessages = []
            return
        }

        onboardingMessages = try await loadOnboardingMessages(accountUserID: accountUserID)
    }

    private func persistOnboardingMessages() async throws {
        guard let activeAccountUserID else { return }

        let record = DraftRecord(
            id: OnboardingConversationDraftID.make(accountUserID: activeAccountUserID),
            accountUserID: activeAccountUserID,
            kind: .onboardingConversation,
            payloadData: try OnboardingConversationCodec.encode(onboardingMessages),
            updatedAt: Date()
        )
        try await localStore.upsertDraft(record)
    }

    private func loadOnboardingMessages(accountUserID: UUID) async throws -> [OnboardingMessage] {
        let draftID = OnboardingConversationDraftID.make(accountUserID: accountUserID)
        let drafts = try await localStore.fetchDrafts(accountUserID: accountUserID)
        guard let draft = drafts.first(where: { $0.id == draftID && $0.kind == .onboardingConversation }) else {
            return []
        }
        return try OnboardingConversationCodec.decode(draft.payloadData)
    }

    private func clearOnboardingConversationCache(accountUserID: UUID) async throws {
        try await localStore.deleteDraft(
            id: OnboardingConversationDraftID.make(accountUserID: accountUserID),
            accountUserID: accountUserID
        )
    }

    private func probeHealthLiveIfNeeded() async {
        guard let healthLiveProbe else { return }

        do {
            let status = try await healthLiveProbe()
            KelinLog.launch.debug("health_live status=\(status)")
        } catch let error as AppError {
            KelinLog.launch.error(
                "health_live error_code=\(error.diagnosticCode)"
            )
        } catch {
            KelinLog.launch.error("health_live error_code=NETWORK_UNAVAILABLE")
        }
    }

    private func nextOnboardingClientMessageID(for content: String) -> UUID {
        if let existing = pendingOnboardingClientMessageID {
            if pendingOnboardingChatContent == nil || pendingOnboardingChatContent == content {
                pendingOnboardingChatContent = content
                return existing
            }
        }

        let id = UUID()
        pendingOnboardingClientMessageID = id
        pendingOnboardingChatContent = content
        return id
    }

    private func shouldRecoverFromAuthoritativeError(_ error: AppError) -> Bool {
        switch error {
        case .conflict, .unknown:
            true
        default:
            false
        }
    }

    private func recoverFromAuthoritativeError(_ error: AppError) async -> Bool {
        guard shouldRecoverFromAuthoritativeError(error) else {
            return false
        }

        do {
            try await refreshAuthoritativeSnapshot()
        } catch {
            return false
        }

        guard let snapshot = sessionStore.snapshot else {
            return false
        }

        let next = resolvePhase(from: snapshot)
        switch next {
        case .needsAgreement:
            return false
        default:
            break
        }

        if snapshot.spirit != nil {
            pendingSpiritClientID = nil
        }
        if snapshot.onboarding.completedAt != nil {
            pendingOnboardingClientMessageID = nil
            pendingOnboardingChatContent = nil
            pendingOnboardingCompleteClientID = nil
        }

        hatchError = nil
        onboardingChatError = nil
        onboardingCompleteError = nil
        phase = next
        await persistStableIDsIfPossible()
        scheduleOnboardingCompleteIfNeeded()
        KelinLog.onboarding.info(
            "authoritative_recover error_code=\(error.diagnosticCode) \(KelinLog.snapshotSummary(snapshot)) phase=\(self.phase.diagnosticName)"
        )
        return true
    }

    func refreshSnapshotVersionForSettings() async throws -> Int {
        try await refreshAuthoritativeSnapshot()
        isOffline = false
        isShowingCachedSnapshot = false
        lastSuccessfulBootstrapAt = Date()
        return sessionStore.snapshot?.snapshotVersion ?? 0
    }

    func registerDeviceIfPossible(enabled: Bool? = nil) async {
        guard usesRemoteAPI, P16P20ContractManifest.liveHasDeviceRoute else {
            return
        }
        guard phase == .ready || enabled != nil else {
            return
        }

        let pushOn = enabled ?? sessionStore.snapshot?.spirit?.preferences.pushOn ?? true
        if pushOn {
            DeviceTokenCenter.requestRemoteNotificationsIfNeeded()
        }

        guard let token = DeviceTokenCenter.apnsToken, token.count >= 16 else {
            KelinLog.api.info("device_register_skipped reason=missing_apns_token")
            return
        }

        let environment = DeviceAPNsEnvironment.current
        let installationID = DeviceInstallationStore.installationID()
        let clientID = DeviceInstallationStore.clientID(environment: environment, enabled: pushOn)
        do {
            let registration = try await deviceService.register(
                installationID: installationID,
                apnsToken: token,
                environment: environment,
                enabled: pushOn,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                locale: Locale.current.identifier,
                clientID: clientID
            )
            KelinLog.api.info(
                "device_register_ok device=\(KelinLog.shortID(registration.deviceID)) enabled=\(registration.enabled) environment=\(environment)"
            )
        } catch let error as AppError {
            KelinLog.api.error("device_register_failed error_code=\(error.diagnosticCode)")
        } catch {
            KelinLog.api.error("device_register_failed error_code=UNKNOWN")
        }
    }

    private func applyAuthoritativePatch(_ patch: SessionPatch) {
        do {
            try sessionStore.apply(patch)
        } catch let error as SessionStoreError {
            KelinLog.onboarding.error(
                "authoritative_patch_rejected error=\(String(describing: error))"
            )
            if sessionStore.needsBootstrapRefresh {
                Task { await refreshAuthoritativeSnapshotIfRemote() }
            }
        } catch {
            KelinLog.onboarding.error("authoritative_patch_rejected error_code=UNKNOWN")
        }
    }

    private func refreshAuthoritativeSnapshotIfRemote() async {
        guard usesRemoteAPI, sessionStore.snapshot != nil else { return }

        do {
            try await refreshAuthoritativeSnapshot()
            isOffline = false
            isShowingCachedSnapshot = false
            lastSuccessfulBootstrapAt = Date()
        } catch let error as AppError {
            if sessionStore.snapshot != nil {
                isOffline = true
            }
            KelinLog.onboarding.error(
                "bootstrap_refresh_failed error_code=\(error.diagnosticCode) offline_cache=\(self.sessionStore.snapshot != nil)"
            )
        } catch {
            if sessionStore.snapshot != nil {
                isOffline = true
            }
            KelinLog.onboarding.error(
                "bootstrap_refresh_failed error_code=UNKNOWN offline_cache=\(self.sessionStore.snapshot != nil)"
            )
        }
    }

    private func refreshAuthoritativeSnapshot() async throws {
        let cachedSnapshot = sessionStore.snapshot
        let freshSnapshot = try await bootstrapCoordinator.fetch(using: bootstrapService)
        let mergedSnapshot = mergeBootstrapSnapshots(cached: cachedSnapshot, fresh: freshSnapshot)
        sessionStore.replace(with: mergedSnapshot)

        if let activeAccountUserID {
            try await persistSnapshot(mergedSnapshot, accountUserID: activeAccountUserID)
        }
    }

    private func restoreStableIDs(for accountUserID: UUID, snapshot: BootstrapSnapshot) async {
        let stored = try? await loadStableIDs(accountUserID: accountUserID)

        if snapshot.spirit == nil {
            pendingSpiritClientID = stored?.spiritClientID
        } else {
            pendingSpiritClientID = nil
        }

        if snapshot.spirit != nil, snapshot.onboarding.completedAt == nil {
            pendingOnboardingClientMessageID = stored?.chatClientMessageID
            pendingOnboardingChatContent = stored?.chatContent
            pendingOnboardingCompleteClientID = stored?.completeClientID
        } else {
            pendingOnboardingClientMessageID = nil
            pendingOnboardingChatContent = nil
            pendingOnboardingCompleteClientID = nil
        }

    }

    private func persistStableIDsIfPossible() async {
        guard let activeAccountUserID else { return }

        let ids = OnboardingStableIDs(
            spiritClientID: pendingSpiritClientID,
            chatClientMessageID: pendingOnboardingClientMessageID,
            chatContent: pendingOnboardingChatContent,
            completeClientID: pendingOnboardingCompleteClientID
        )

        do {
            try await persistStableIDs(ids, accountUserID: activeAccountUserID)
        } catch {
            KelinLog.onboarding.error("stable_ids_persist_failed")
        }
    }

    private func persistStableIDs(_ ids: OnboardingStableIDs, accountUserID: UUID) async throws {
        let existing = try await loadStableIDsDraft(accountUserID: accountUserID)
        let record = DraftRecord(
            id: existing?.id ?? OnboardingStableIDsDraftID.make(accountUserID: accountUserID),
            accountUserID: accountUserID,
            kind: .onboardingStableIDs,
            payloadData: try OnboardingStableIDsCodec.encode(ids),
            updatedAt: Date()
        )
        try await localStore.upsertDraft(record)
    }

    private func loadStableIDs(accountUserID: UUID) async throws -> OnboardingStableIDs? {
        guard let draft = try await loadStableIDsDraft(accountUserID: accountUserID) else {
            return nil
        }
        return try OnboardingStableIDsCodec.decode(draft.payloadData)
    }

    private func loadStableIDsDraft(accountUserID: UUID) async throws -> DraftRecord? {
        let drafts = try await localStore.fetchDrafts(accountUserID: accountUserID)
        return drafts.first(where: { $0.kind == .onboardingStableIDs })
    }

    private func logOnboardingError(_ event: String, _ error: AppError) {
        if let requestID = error.diagnosticRequestID {
            KelinLog.onboarding.error(
                "\(event) error_code=\(error.diagnosticCode) request_id=\(requestID)"
            )
        } else {
            KelinLog.onboarding.error(
                "\(event) error_code=\(error.diagnosticCode)"
            )
        }
    }
}
