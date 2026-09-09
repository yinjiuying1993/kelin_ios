import Foundation
import Supabase

actor SupabaseAuthService: AuthServiceProtocol {
    private let client: SupabaseClient

    init(config: AppConfig) {
        client = SupabaseClient(
            supabaseURL: config.supabaseURL,
            supabaseKey: config.supabaseAnonKey
        )
    }

    func restoreSession() async throws -> AuthSession? {
        guard client.auth.currentSession != nil else {
            KelinLog.auth.info("restore_session result=none")
            return nil
        }

        do {
            let session = try await client.auth.session
            let mapped = try mapSession(session)
            KelinLog.auth.info("restore_session result=ok user=\(KelinLog.shortID(mapped.userID), privacy: .public)")
            return mapped
        } catch {
            KelinLog.auth.info("restore_session result=none")
            return nil
        }
    }

    func signInAnonymously() async throws -> AuthSession {
        try Task.checkCancellation()

        do {
            let session = try await client.auth.signInAnonymously()
            let mapped = try mapSession(session)
            KelinLog.auth.info("sign_in_anonymously result=ok user=\(KelinLog.shortID(mapped.userID), privacy: .public)")
            return mapped
        } catch is CancellationError {
            throw AppError.cancelled
        } catch {
            let mapped = mapAuthError(error)
            KelinLog.auth.error("sign_in_anonymously result=error error_code=\(mapped.diagnosticCode, privacy: .public)")
            throw mapped
        }
    }

    func refreshSession() async throws -> AuthSession {
        try Task.checkCancellation()

        do {
            let session = try await client.auth.refreshSession()
            let mapped = try mapSession(session)
            KelinLog.auth.info("refresh_session result=ok user=\(KelinLog.shortID(mapped.userID), privacy: .public)")
            return mapped
        } catch is CancellationError {
            throw AppError.cancelled
        } catch {
            let mapped = mapAuthError(error)
            KelinLog.auth.error("refresh_session result=error error_code=\(mapped.diagnosticCode, privacy: .public)")
            throw mapped
        }
    }

    func currentAccessToken() async throws -> String {
        try Task.checkCancellation()

        do {
            let session = try await client.auth.session
            return session.accessToken
        } catch is CancellationError {
            throw AppError.cancelled
        } catch {
            throw mapAuthError(error)
        }
    }

    func signOut() async throws {
        try Task.checkCancellation()

        do {
            try await client.auth.signOut()
        } catch is CancellationError {
            throw AppError.cancelled
        } catch {
            throw mapAuthError(error)
        }
    }

    private func mapSession(_ session: Session) throws -> AuthSession {
        AuthSession(
            userID: session.user.id,
            accessToken: session.accessToken,
            expiresAt: Date(timeIntervalSince1970: session.expiresAt)
        )
    }

    private func mapAuthError(_ error: Error) -> AppError {
        if let authError = error as? AuthError, authError == .sessionMissing {
            return .unauthenticated
        }
        return .networkUnavailable
    }
}
