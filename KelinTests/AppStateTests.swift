import XCTest
@testable import Kelin

@MainActor
final class AppStateTests: XCTestCase {
    func testExistingSessionSkipsAnonymousSignIn() async {
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
        let appState = AppState(auth: auth)

        appState.beginLaunch()
        await waitForPhase(.ready, in: appState)

        let calls = await auth.recordedCalls()
        XCTAssertEqual(calls, [.restoreSession])
    }

    func testMissingSessionSignsInAnonymously() async {
        let auth = MockAuthService()
        let appState = AppState(auth: auth)

        appState.beginLaunch()
        await waitForPhase(.ready, in: appState)

        let calls = await auth.recordedCalls()
        XCTAssertEqual(calls, [.restoreSession, .signInAnonymously])
    }

    func testRestoreFailureShowsRecoverableError() async {
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                restoreError: .networkUnavailable
            )
        )
        let appState = AppState(auth: auth)

        appState.beginLaunch()
        await waitForPhase(.recoverableError(.networkUnavailable), in: appState)
    }

    func testAnonymousSignInFailureShowsRecoverableError() async {
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                signInError: .networkUnavailable
            )
        )
        let appState = AppState(auth: auth)

        appState.beginLaunch()
        await waitForPhase(.recoverableError(.networkUnavailable), in: appState)

        let calls = await auth.recordedCalls()
        XCTAssertEqual(calls, [.restoreSession, .signInAnonymously])
    }

    func testRetryFromErrorRestartsLaunchFlow() async {
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                restoreError: .networkUnavailable
            )
        )
        let appState = AppState(auth: auth)

        appState.beginLaunch()
        await waitForPhase(.recoverableError(.networkUnavailable), in: appState)

        await auth.setConfiguration(MockAuthConfiguration())
        appState.retryFromError()
        await waitForPhase(.ready, in: appState)
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
