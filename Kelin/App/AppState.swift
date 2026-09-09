import Foundation

@MainActor
@Observable
final class AppState {
    let sessionStore: SessionStore

    private(set) var phase: AppPhase = .launching
    private(set) var isOffline = false
    private(set) var isShowingCachedSnapshot = false
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
    private let bootstrapCoordinator: BootstrapCoordinator
    private let syncCoordinator: SyncCoordinator?
    private let hatchAnimationDuration: Duration

    private var launchTask: Task<Void, Never>?
    private var completeOnboardingTask: Task<Void, Never>?
    private var activeAccountUserID: UUID?
    private var pendingSpiritClientID: UUID?
    private var pendingOnboardingClientMessageID: UUID?
    private var pendingOnboardingCompleteClientID: UUID?

    init(
        auth: any AuthServiceProtocol,
        localStore: LocalStore,
        bootstrapService: any BootstrapServiceProtocol,
        agreementGate: any AgreementGateServiceProtocol = MockAgreementGateService(),
        hatchService: any HatchServiceProtocol = MockHatchService(),
        onboardingChatService: any OnboardingChatServiceProtocol = MockOnboardingChatService(),
        onboardingCompleteService: any OnboardingCompleteServiceProtocol = MockOnboardingCompleteService(),
        sessionStore: SessionStore = SessionStore(),
        bootstrapCoordinator: BootstrapCoordinator = BootstrapCoordinator(),
        syncCoordinator: SyncCoordinator? = nil,
        hatchAnimationDuration: Duration = .milliseconds(1_000),
        usesRemoteAPI: Bool = false,
        apiBaseURL: URL? = nil
    ) {
        self.auth = auth
        self.localStore = localStore
        self.bootstrapService = bootstrapService
        self.agreementGate = agreementGate
        self.hatchService = hatchService
        self.onboardingChatService = onboardingChatService
        self.onboardingCompleteService = onboardingCompleteService
        self.sessionStore = sessionStore
        self.bootstrapCoordinator = bootstrapCoordinator
        self.syncCoordinator = syncCoordinator
        self.hatchAnimationDuration = hatchAnimationDuration
        self.usesRemoteAPI = usesRemoteAPI
        self.apiBaseURL = apiBaseURL
    }

    func failBeforeLaunch(_ error: AppError) {
        phase = .recoverableError(error)
    }

    func discardLocalCacheAndReload() async {
        if let activeAccountUserID {
            try? await localStore.clearAccount(accountUserID: activeAccountUserID)
            try? await clearOnboardingConversationCache(accountUserID: activeAccountUserID)
        }

        sessionStore.clear()
        onboardingMessages = []
        pendingConsents = nil
        pendingSpiritClientID = nil
        pendingOnboardingClientMessageID = nil
        pendingOnboardingCompleteClientID = nil
        isOffline = false
        isShowingCachedSnapshot = false
        beginLaunch()
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
        } catch let error as AppError {
            agreementError = error
        } catch {
            agreementError = .unknown(requestID: "")
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

        if pendingOnboardingClientMessageID == nil {
            pendingOnboardingClientMessageID = UUID()
        }

        let completedRounds = sessionStore.snapshot?.onboarding.step ?? 0

        do {
            let result = try await onboardingChatService.sendOnboardingMessage(
                clientMessageID: pendingOnboardingClientMessageID!,
                content: trimmed,
                completedRounds: completedRounds
            )

            onboardingMessages.append(result.userMessage)
            onboardingMessages.append(result.spiritMessage)
            onboardingChatServiceUsesStub = result.usesStubProvider
            pendingOnboardingClientMessageID = nil

            try await applyOnboardingChatResult(result)
            try await persistOnboardingMessages()
            phase = .needsFirstConversation(
                step: min(result.completedRounds + 1, OnboardingConversationDefaults.totalSteps)
            )

            if result.completedRounds >= OnboardingConversationDefaults.totalSteps {
                scheduleOnboardingCompleteIfNeeded()
            }
        } catch let error as AppError {
            onboardingChatError = error
        } catch {
            onboardingChatError = .unknown(requestID: "")
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
            spirit: base.spirit,
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

        hatchError = nil
        isSubmittingHatch = true
        defer { isSubmittingHatch = false }

        if pendingSpiritClientID == nil {
            pendingSpiritClientID = UUID()
        }

        let request = CreateSpiritRequest(
            clientID: pendingSpiritClientID!,
            egg: selectedOption.eggType,
            name: HatchDefaults.placeholderSpiritName,
            consents: consents
        )

        do {
            let result = try await hatchService.createSpirit(request)
            try await applyCreateSpiritResult(result)
            pendingSpiritClientID = nil
            onboardingMessages = []
            pendingOnboardingCompleteClientID = UUID()
            if let activeAccountUserID {
                try await clearOnboardingConversationCache(accountUserID: activeAccountUserID)
            }
            phase = .needsFirstConversation(step: 1)
        } catch let error as AppError {
            hatchError = error
        } catch {
            hatchError = .unknown(requestID: "")
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
            room: base.room,
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

        do {
            try Task.checkCancellation()
            phase = .restoringSession

            let session = try await resolveSession()
            activeAccountUserID = session.userID

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
            phase = resolvePhase(from: mergedSnapshot)
            scheduleOnboardingCompleteIfNeeded()
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
            return
        }

        phase = .recoverableError(error)
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

            let result = try await onboardingCompleteService.completeOnboarding(
                clientID: pendingOnboardingCompleteClientID!,
                expectedSpiritVersion: spirit.version
            )

            try await applyOnboardingCompleteResult(result)
            pendingOnboardingCompleteClientID = nil

            if let activeAccountUserID {
                try await clearOnboardingConversationCache(accountUserID: activeAccountUserID)
            }

            phase = .ready
        } catch is CancellationError {
            return
        } catch let error as AppError {
            onboardingCompleteError = error
        } catch {
            onboardingCompleteError = .unknown(requestID: "")
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
            return fresh
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
}
