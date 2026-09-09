import Supabase
import XCTest
@testable import Kelin

final class MockAuthServiceTests: XCTestCase {
    func testRefreshRequiresStoredSession() async {
        let auth = MockAuthService()

        do {
            _ = try await auth.refreshSession()
            XCTFail("Expected unauthenticated")
        } catch AppError.unauthenticated {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSignOutClearsStoredSession() async throws {
        let auth = MockAuthService()
        _ = try await auth.signInAnonymously()

        try await auth.signOut()

        do {
            _ = try await auth.currentAccessToken()
            XCTFail("Expected unauthenticated")
        } catch AppError.unauthenticated {
            XCTAssertTrue(true)
        }
    }

    func testRecordsCallsInOrder() async throws {
        let auth = MockAuthService()
        _ = try await auth.restoreSession()
        _ = try await auth.signInAnonymously()
        _ = try await auth.currentAccessToken()

        let calls = await auth.recordedCalls()
        XCTAssertEqual(
            calls,
            [.restoreSession, .signInAnonymously, .currentAccessToken]
        )
    }

    func testDelayedRestoreRespectsCancellation() async {
        let auth = MockAuthService(
            configuration: MockAuthConfiguration(
                restoreDelay: .milliseconds(500)
            )
        )

        let task = Task {
            try await auth.restoreSession()
        }

        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

final class SupabaseAuthErrorMapperTests: XCTestCase {
    func testURLErrorMapsToNetworkUnavailable() {
        XCTAssertEqual(
            SupabaseAuthErrorMapper.map(URLError(.notConnectedToInternet)),
            .networkUnavailable
        )
    }

    func testSessionMissingMapsToUnauthenticated() {
        XCTAssertEqual(
            SupabaseAuthErrorMapper.map(AuthError.sessionMissing),
            .unauthenticated
        )
    }

    func testAnonymousProviderDisabledMapsToInvalidInput() {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.supabase.co/auth/v1/signup")!,
            statusCode: 422,
            httpVersion: nil,
            headerFields: nil
        )!
        let error = AuthError.api(
            message: "Anonymous sign-ins are disabled",
            errorCode: .anonymousProviderDisabled,
            underlyingData: Data(),
            underlyingResponse: response
        )

        XCTAssertEqual(SupabaseAuthErrorMapper.map(error), .invalidInput)
        XCTAssertEqual(
            SupabaseAuthErrorMapper.diagnosticDetail(error),
            "supabase_code=anonymous_provider_disabled http_status=422"
        )
    }
}
