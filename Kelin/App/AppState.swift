import Foundation

@MainActor
@Observable
final class AppState {
    let sessionStore: SessionStore

    private(set) var phase: AppPhase = .launching
    private(set) var isOffline = false
    private(set) var isShowingCachedSnapshot = false

    private let auth: any AuthServiceProtocol
    private let localStore: LocalStore
    private let bootstrapService: any BootstrapServiceProtocol
    private let bootstrapCoordinator: BootstrapCoordinator
    private let syncCoordinator: SyncCoordinator?

    private var launchTask: Task<Void, Never>?
    private var activeAccountUserID: UUID?

    init(
        auth: any AuthServiceProtocol,
        localStore: LocalStore,
        bootstrapService: any BootstrapServiceProtocol,
        sessionStore: SessionStore = SessionStore(),
        bootstrapCoordinator: BootstrapCoordinator = BootstrapCoordinator(),
        syncCoordinator: SyncCoordinator? = nil
    ) {
        self.auth = auth
        self.localStore = localStore
        self.bootstrapService = bootstrapService
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
            return .needsFirstConversation(step: snapshot.onboarding.step)
        }

        return .ready
    }
}
