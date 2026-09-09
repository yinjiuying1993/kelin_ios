import Foundation
import Supabase

actor SupabaseAuthService: AuthServiceProtocol {
    private let client: SupabaseClient

    init(config: AppConfig) {
        client = SupabaseClient(
            supabaseURL: config.supabaseURL,
            supabaseKey: config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
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
            KelinLog.auth.info(
                "restore_session result=none \(SupabaseAuthErrorMapper.diagnosticDetail(error), privacy: .public)"
            )
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
            let mapped = SupabaseAuthErrorMapper.map(error)
            KelinLog.auth.error(
                "sign_in_anonymously result=error error_code=\(mapped.diagnosticCode, privacy: .public) \(SupabaseAuthErrorMapper.diagnosticDetail(error), privacy: .public)"
            )
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
            let mapped = SupabaseAuthErrorMapper.map(error)
            KelinLog.auth.error(
                "refresh_session result=error error_code=\(mapped.diagnosticCode, privacy: .public) \(SupabaseAuthErrorMapper.diagnosticDetail(error), privacy: .public)"
            )
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
            throw SupabaseAuthErrorMapper.map(error)
        }
    }

    func signOut() async throws {
        try Task.checkCancellation()

        do {
            try await client.auth.signOut()
        } catch is CancellationError {
            throw AppError.cancelled
        } catch {
            throw SupabaseAuthErrorMapper.map(error)
        }
    }

    private func mapSession(_ session: Session) throws -> AuthSession {
        AuthSession(
            userID: session.user.id,
            accessToken: session.accessToken,
            expiresAt: Date(timeIntervalSince1970: session.expiresAt)
        )
    }
}

enum SupabaseAuthErrorMapper {
    static func map(_ error: Error) -> AppError {
        if error is CancellationError {
            return .cancelled
        }

        if let urlError = error as? URLError {
            return urlError.code == .timedOut ? .timedOut : .networkUnavailable
        }

        guard let authError = error as? AuthError else {
            return .unknown(requestID: "")
        }

        switch authError {
        case .sessionMissing:
            return .unauthenticated
        case let .api(_, errorCode, _, response):
            if response.statusCode == 401 {
                return .unauthenticated
            }
            if errorCode == .anonymousProviderDisabled || errorCode == .signupDisabled {
                return .invalidInput
            }
            return .unknown(requestID: errorCode.rawValue)
        default:
            return .unknown(requestID: "")
        }
    }

    static func diagnosticDetail(_ error: Error) -> String {
        if let urlError = error as? URLError {
            return "url_error=\(urlError.code.rawValue)"
        }

        guard let authError = error as? AuthError else {
            return "error_type=\(String(describing: type(of: error)))"
        }

        switch authError {
        case .sessionMissing:
            return "supabase_code=session_missing"
        case let .api(_, errorCode, _, response):
            return "supabase_code=\(errorCode.rawValue) http_status=\(response.statusCode)"
        default:
            return "supabase_code=unmapped"
        }
    }
}
