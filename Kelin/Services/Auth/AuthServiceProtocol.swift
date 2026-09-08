import Foundation

enum AuthCall: Equatable, Sendable {
    case restoreSession
    case signInAnonymously
    case refreshSession
    case currentAccessToken
    case signOut
}

protocol AuthServiceProtocol: Sendable {
    func restoreSession() async throws -> AuthSession?
    func signInAnonymously() async throws -> AuthSession
    func refreshSession() async throws -> AuthSession
    func currentAccessToken() async throws -> String
    func signOut() async throws
}
