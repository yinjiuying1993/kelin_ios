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
            return nil
        }

        do {
            let session = try await client.auth.session
            return try mapSession(session)
        } catch {
            return nil
        }
    }

    func signInAnonymously() async throws -> AuthSession {
        try Task.checkCancellation()

        do {
            let session = try await client.auth.signInAnonymously()
            return try mapSession(session)
        } catch is CancellationError {
            throw AppError.cancelled
        } catch {
            throw mapAuthError(error)
        }
    }

    func refreshSession() async throws -> AuthSession {
        try Task.checkCancellation()

        do {
            let session = try await client.auth.refreshSession()
            return try mapSession(session)
        } catch is CancellationError {
            throw AppError.cancelled
        } catch {
            throw mapAuthError(error)
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
