import Foundation

@MainActor
@Observable
final class AppState {
    private(set) var phase: AppPhase = .launching

    private let auth: any AuthServiceProtocol
    private var launchTask: Task<Void, Never>?

    init(auth: any AuthServiceProtocol) {
        self.auth = auth
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
        phase = .restoringSession

        do {
            try Task.checkCancellation()

            if let session = try await auth.restoreSession() {
                _ = session
                phase = .ready
                return
            }

            try Task.checkCancellation()
            phase = .signingInAnonymously
            _ = try await auth.signInAnonymously()

            try Task.checkCancellation()
            phase = .ready
        } catch is CancellationError {
            return
        } catch let error as AppError {
            phase = .recoverableError(error)
        } catch {
            phase = .recoverableError(.unknown(requestID: ""))
        }
    }
}
