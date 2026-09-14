import XCTest
@testable import Kelin

final class APIClientTests: XCTestCase {
    private var auth: MockAuthService!
    private var config: AppConfig!

    override func setUp() async throws {
        auth = MockAuthService(
            configuration: MockAuthConfiguration(
                storedSession: AuthSession(
                    userID: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
                    accessToken: "mock-access-token",
                    expiresAt: Date().addingTimeInterval(3_600)
                )
            )
        )
        config = try AppConfig(infoDictionary: [
            AppConfig.Key.supabaseURL: "https://example.supabase.co",
            AppConfig.Key.supabaseAnonKey: "synthetic-anon-key",
            AppConfig.Key.apiBaseURL: "https://api.example.com",
            AppConfig.Key.appEnvironment: "dev",
        ])
    }

    override func tearDown() async throws {
        StubURLProtocol.requestHandler = nil
        auth = nil
        config = nil
    }

    func testSuccessfulRequestBuildsHeadersAndDecodesEnvelope() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Self.successEnvelopeData())
        }

        let client = APIClient(
            config: config,
            auth: auth,
            urlSession: StubURLSessionFactory.make()
        )

        let payload: PingResponse = try await client.send(
            .get("/ping"),
            responseType: PingResponse.self
        )

        XCTAssertEqual(payload.message, "pong")
        XCTAssertEqual(capturedRequest?.httpMethod, "GET")
        XCTAssertEqual(
            capturedRequest?.url?.absoluteString,
            "https://api.example.com/api/v1/ping"
        )
        XCTAssertEqual(
            capturedRequest?.value(forHTTPHeaderField: "Authorization"),
            "Bearer mock-access-token"
        )
        XCTAssertNotNil(capturedRequest?.value(forHTTPHeaderField: "X-Request-ID"))
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testAccepted202EnvelopeIsSuccess() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 202,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Self.successEnvelopeData())
        }

        let client = APIClient(
            config: config,
            auth: auth,
            urlSession: StubURLSessionFactory.make()
        )

        let payload: PingResponse = try await client.send(
            .delete("/account", body: Data("{}".utf8)),
            responseType: PingResponse.self
        )
        XCTAssertEqual(payload.message, "pong")
    }

    func testUnauthorizedRefreshesSessionOnceAndRetries() async throws {
        var attemptCount = 0
        StubURLProtocol.requestHandler = { request in
            attemptCount += 1
            let statusCode = attemptCount == 1 ? 401 : 200
            let body = attemptCount == 1 ? Data("{}".utf8) : Self.successEnvelopeData()
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, body)
        }

        let client = APIClient(
            config: config,
            auth: auth,
            urlSession: StubURLSessionFactory.make()
        )

        let payload: PingResponse = try await client.send(
            .get("/ping"),
            responseType: PingResponse.self
        )

        XCTAssertEqual(payload.message, "pong")
        XCTAssertEqual(attemptCount, 2)

        let calls = await auth.recordedCalls()
        XCTAssertEqual(calls.filter { $0 == .refreshSession }.count, 1)
        XCTAssertEqual(calls.filter { $0 == .currentAccessToken }.count, 2)
    }

    func testRepeatedUnauthorizedFailsAfterSingleRefresh() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{}".utf8))
        }

        let client = APIClient(
            config: config,
            auth: auth,
            urlSession: StubURLSessionFactory.make()
        )

        do {
            _ = try await client.send(.get("/ping"), responseType: PingResponse.self)
            XCTFail("Expected unauthenticated error")
        } catch let error as AppError {
            XCTAssertEqual(error, .unauthenticated)
        }

        let calls = await auth.recordedCalls()
        XCTAssertEqual(calls.filter { $0 == .refreshSession }.count, 1)
    }

    func testBusinessErrorMapsToAppError() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let body = """
            {
              "ok": false,
              "data": null,
              "error": {
                "code": "QUOTA_EXCEEDED",
                "message": "quota exceeded",
                "retryable": false,
                "details": {"quota": "tts"}
              },
              "request_id": "req-quota",
              "server_time": "2026-09-07T03:46:00Z"
            }
            """.data(using: .utf8)!
            return (response, body)
        }

        let client = APIClient(
            config: config,
            auth: auth,
            urlSession: StubURLSessionFactory.make()
        )

        do {
            _ = try await client.send(.get("/ping"), responseType: PingResponse.self)
            XCTFail("Expected quota error")
        } catch let error as AppError {
            XCTAssertEqual(error, .quotaExceeded(.tts, resetAt: nil))
        }
    }

    func testQuotaExceededReadsResetAtFromDetails() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let body = """
            {
              "ok": false,
              "data": null,
              "error": {
                "code": "QUOTA_EXCEEDED",
                "message": "quota exceeded",
                "retryable": false,
                "details": {"quota": "food", "reset_at": "2026-09-12T16:00:00Z"}
              },
              "request_id": "req-quota-reset",
              "server_time": "2026-09-11T09:00:00Z"
            }
            """.data(using: .utf8)!
            return (response, body)
        }

        let client = APIClient(
            config: config,
            auth: auth,
            urlSession: StubURLSessionFactory.make()
        )

        do {
            _ = try await client.send(.get("/ping"), responseType: PingResponse.self)
            XCTFail("Expected quota error")
        } catch let error as AppError {
            XCTAssertEqual(
                error,
                .quotaExceeded(
                    .food,
                    resetAt: APIDecoding.parseDate("2026-09-12T16:00:00Z")
                )
            )
        }
    }

    func testMissingRequiredFieldFailsDecoding() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let body = """
            {
              "ok": true,
              "data": {},
              "error": null,
              "request_id": "req-missing-field",
              "server_time": "2026-09-07T03:46:00Z"
            }
            """.data(using: .utf8)!
            return (response, body)
        }

        let client = APIClient(
            config: config,
            auth: auth,
            urlSession: StubURLSessionFactory.make()
        )

        do {
            _ = try await client.send(.get("/ping"), responseType: PingResponse.self)
            XCTFail("Expected decoding error")
        } catch let error as AppError {
            XCTAssertEqual(error, .decoding)
        }
    }

    func testTimeoutMapsToTimedOut() async throws {
        StubURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        let client = APIClient(
            config: config,
            auth: auth,
            urlSession: StubURLSessionFactory.make()
        )

        do {
            _ = try await client.send(
                APIEndpoint(path: "/ping", method: .get, timeout: 0.01),
                responseType: PingResponse.self
            )
            XCTFail("Expected timeout error")
        } catch let error as AppError {
            XCTAssertEqual(error, .timedOut)
        }
    }

    func testHealthLiveUsesRootPathWithoutJWTOrEnvelope() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(#"{"status":"live"}"#.utf8))
        }

        let client = APIClient(
            config: config,
            auth: auth,
            urlSession: StubURLSessionFactory.make()
        )

        let status = try await client.checkHealthLive()

        XCTAssertEqual(status, "live")
        XCTAssertEqual(capturedRequest?.url?.absoluteString, "https://api.example.com/health/live")
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"))
    }

    func testMockAPIClientReturnsConfiguredEnvelope() async throws {
        let mockClient = MockAPIClient()
        await mockClient.setResponse(
            MockAPIResponse(data: Self.successEnvelopeData(), statusCode: 200),
            forPath: "/ping"
        )

        let payload: PingResponse = try await mockClient.send(
            .get("/ping"),
            responseType: PingResponse.self
        )

        XCTAssertEqual(payload.message, "pong")
        let paths = await mockClient.requestedPaths
        XCTAssertEqual(paths, ["/ping"])
    }

    private static func successEnvelopeData() -> Data {
        """
        {
          "ok": true,
          "data": {"message": "pong"},
          "error": null,
          "request_id": "req-success",
          "server_time": "2026-09-07T03:46:00Z"
        }
        """.data(using: .utf8)!
    }
}

private struct PingResponse: Decodable, Sendable, Equatable {
    let message: String
}
