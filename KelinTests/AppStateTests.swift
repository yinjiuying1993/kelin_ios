import SwiftData
import XCTest
@testable import Kelin

@MainActor
final class AppStateTests: XCTestCase {
    func testExistingSessionSkipsAnonymousSignIn() async throws {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                storedSession: AuthSession(
                    userID: userID,
                    accessToken: "existing-token",
                    expiresAt: Date().addingTimeInterval(3_600)
                )
            )
        )
        let (appState, _, _) = try makeAppState(auth: auth)

        appState.beginLaunch()
        await waitForPhase(.ready, in: appState)

        let calls = await auth.recordedCalls()
        XCTAssertEqual(calls, [.restoreSession])
    }

    func testMissingSessionSignsInAnonymously() async throws {
        let auth = MockAuthService()
        let (appState, _, _) = try makeAppState(auth: auth)

        appState.beginLaunch()
        await waitForPhase(.ready, in: appState)

        let calls = await auth.recordedCalls()
        XCTAssertEqual(calls, [.restoreSession, .signInAnonymously])
    }

    func testRestoreFailureShowsRecoverableError() async throws {
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                restoreError: .networkUnavailable
            )
        )
        let (appState, _, _) = try makeAppState(auth: auth)

        appState.beginLaunch()
        await waitForPhase(.recoverableError(.networkUnavailable), in: appState)
    }

    func testAnonymousSignInFailureShowsRecoverableError() async throws {
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                signInError: .networkUnavailable
            )
        )
        let (appState, _, _) = try makeAppState(auth: auth)

        appState.beginLaunch()
        await waitForPhase(.recoverableError(.networkUnavailable), in: appState)

        let calls = await auth.recordedCalls()
        XCTAssertEqual(calls, [.restoreSession, .signInAnonymously])
    }

    func testRetryFromErrorRestartsLaunchFlow() async throws {
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                restoreError: .networkUnavailable
            )
        )
        let (appState, _, _) = try makeAppState(auth: auth)

        appState.beginLaunch()
        await waitForPhase(.recoverableError(.networkUnavailable), in: appState)

        await auth.setConfiguration(MockAuthConfiguration())
        appState.retryFromError()
        await waitForPhase(.ready, in: appState)
    }

    private func makeAppState(
        auth: MockAuthService = MockAuthService(),
        bootstrap: MockBootstrapService = MockBootstrapService(mode: .fullUser)
    ) throws -> (AppState, ModelContainer, MockBootstrapService) {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let appState = AppState(
            auth: auth,
            localStore: LocalStore(modelContainer: container),
            bootstrapService: bootstrap
        )
        return (appState, container, bootstrap)
    }

    private func waitForPhase(
        _ expected: AppPhase,
        in appState: AppState,
        timeout: Duration = .seconds(2)
    ) async {
        let deadline = ContinuousClock.now + timeout

        while ContinuousClock.now < deadline {
            if appState.phase == expected {
                return
            }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }

        XCTFail("Expected phase \(expected), got \(appState.phase)")
    }
}
