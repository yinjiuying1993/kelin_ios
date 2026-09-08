import Foundation

struct MockAuthConfiguration: Sendable {
    var storedSession: AuthSession?
    var restoreError: AppError?
    var signInError: AppError?
    var refreshError: AppError?
    var restoreDelay: Duration?
    var signInDelay: Duration?
}

actor MockAuthService: AuthServiceProtocol {
    private var configuration: MockAuthConfiguration
    private(set) var calls: [AuthCall] = []

    init(configuration: MockAuthConfiguration = MockAuthConfiguration()) {
        self.configuration = configuration
    }

    func setConfiguration(_ configuration: MockAuthConfiguration) {
        self.configuration = configuration
    }

    func recordedCalls() -> [AuthCall] {
        calls
    }

    func restoreSession() async throws -> AuthSession? {
        calls.append(.restoreSession)

        if let restoreDelay = configuration.restoreDelay {
            try await Task.sleep(for: restoreDelay)
        }

        try Task.checkCancellation()

        if let restoreError = configuration.restoreError {
            throw restoreError
        }

        return configuration.storedSession
    }

    func signInAnonymously() async throws -> AuthSession {
        calls.append(.signInAnonymously)

        if let signInDelay = configuration.signInDelay {
            try await Task.sleep(for: signInDelay)
        }

        try Task.checkCancellation()

        if let signInError = configuration.signInError {
            throw signInError
        }

        let session = configuration.storedSession ?? Self.makeSession()
        configuration.storedSession = session
        return session
    }

    func refreshSession() async throws -> AuthSession {
        calls.append(.refreshSession)

        try Task.checkCancellation()

        if let refreshError = configuration.refreshError {
            throw refreshError
        }

        guard let session = configuration.storedSession else {
            throw AppError.unauthenticated
        }

        let refreshed = AuthSession(
            userID: session.userID,
            accessToken: "mock-refreshed-token-\(session.userID.uuidString)",
            expiresAt: session.expiresAt.addingTimeInterval(3_600)
        )
        configuration.storedSession = refreshed
        return refreshed
    }

    func currentAccessToken() async throws -> String {
        calls.append(.currentAccessToken)

        try Task.checkCancellation()

        guard let session = configuration.storedSession else {
            throw AppError.unauthenticated
        }

        return session.accessToken
    }

    func signOut() async throws {
        calls.append(.signOut)
        configuration.storedSession = nil
    }

    private static func makeSession() -> AuthSession {
        AuthSession(
            userID: UUID(),
            accessToken: "mock-access-token",
            expiresAt: Date().addingTimeInterval(3_600)
        )
    }
}
