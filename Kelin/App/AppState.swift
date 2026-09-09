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

    var hasCompletedOnboardingConversation: Bool {
        (sessionStore.snapshot?.onboarding.step ?? 0) >= OnboardingConversationDefaults.totalSteps
    }

    private let auth: any AuthServiceProtocol
    private let localStore: LocalStore
    private let bootstrapService: any BootstrapServiceProtocol
    private let agreementGate: any AgreementGateServiceProtocol
    private let hatchService: any HatchServiceProtocol
    private let onboardingChatService: any OnboardingChatServiceProtocol
    private let bootstrapCoordinator: BootstrapCoordinator
    private let syncCoordinator: SyncCoordinator?

    private var launchTask: Task<Void, Never>?
    private var activeAccountUserID: UUID?
    private var pendingSpiritClientID: UUID?
    private var pendingOnboardingClientMessageID: UUID?

    init(
        auth: any AuthServiceProtocol,
        localStore: LocalStore,
        bootstrapService: any BootstrapServiceProtocol,
        agreementGate: any AgreementGateServiceProtocol = MockAgreementGateService(),
        hatchService: any HatchServiceProtocol = MockHatchService(),
        onboardingChatService: any OnboardingChatServiceProtocol = MockOnboardingChatService(),
        sessionStore: SessionStore = SessionStore(),
        bootstrapCoordinator: BootstrapCoordinator = BootstrapCoordinator(),
        syncCoordinator: SyncCoordinator? = nil
    ) {
        self.auth = auth
        self.localStore = localStore
        self.bootstrapService = bootstrapService
        self.agreementGate = agreementGate
        self.hatchService = hatchService
        self.onboardingChatService = onboardingChatService
        self.sessionStore = sessionStore
        self.bootstrapCoordinator = bootstrapCoordinator
        self.syncCoordinator = syncCoordinator
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
            phase = .needsFirstConversation(
                step: min(result.completedRounds + 1, OnboardingConversationDefaults.totalSteps)
            )
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

            let freshSnapshot = try await bootstrapCoordinator.fetch(using: bootstrapService)
            sessionStore.replace(with: freshSnapshot)
            try await persistSnapshot(freshSnapshot, accountUserID: session.userID)

            isShowingCachedSnapshot = false
            isOffline = false
            phase = resolvePhase(from: freshSnapshot)
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
}
