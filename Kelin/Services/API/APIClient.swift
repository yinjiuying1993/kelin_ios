import Foundation

actor APIClient: APIClientProtocol {
    private let config: AppConfig
    private let auth: any AuthServiceProtocol
    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder

    init(
        config: AppConfig,
        auth: any AuthServiceProtocol,
        urlSession: URLSession = .shared
    ) {
        self.config = config
        self.auth = auth
        self.urlSession = urlSession
        self.jsonDecoder = APIDecoding.makeJSONDecoder()
    }

    func send<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        try await sendWithMetadata(endpoint, responseType: responseType).payload
    }

    func sendWithMetadata<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> APISendResult<T> {
        var didRefreshSession = false

        while true {
            do {
                return try await performRequest(endpoint, responseType: responseType)
            } catch let error as AppError where error == .unauthenticated && !didRefreshSession {
                KelinLog.api.info("auth_refresh endpoint=\(endpoint.path, privacy: .public)")
                _ = try await auth.refreshSession()
                didRefreshSession = true
            }
        }
    }

    private func performRequest<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> APISendResult<T> {
        var connectionAttempt = 0

        while true {
            do {
                return try await executeRequest(endpoint, responseType: responseType)
            } catch let error as AppError where error == .networkUnavailable && endpoint.allowsConnectionRetry {
                connectionAttempt += 1
                KelinLog.api.info(
                    "connection_retry endpoint=\(endpoint.path, privacy: .public) attempt=\(connectionAttempt)"
                )
                guard connectionAttempt <= 2 else {
                    throw AppError.networkUnavailable
                }

                let delay = connectionAttempt == 1 ? 0.5 : 1.5
                try await Task.sleep(for: .seconds(delay))
            }
        }
    }

    private func executeRequest<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> APISendResult<T> {
        let prepared = try await makeURLRequest(for: endpoint)
        let startedAt = ContinuousClock.now

        KelinLog.api.info(
            "request method=\(endpoint.method.rawValue, privacy: .public) endpoint=\(endpoint.path, privacy: .public) request_id=\(prepared.requestID, privacy: .public)"
        )

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await urlSession.data(for: prepared.request)
        } catch is CancellationError {
            throw AppError.cancelled
        } catch let error as URLError {
            let latency = elapsedMilliseconds(since: startedAt)
            KelinLog.api.error(
                "transport method=\(endpoint.method.rawValue, privacy: .public) endpoint=\(endpoint.path, privacy: .public) request_id=\(prepared.requestID, privacy: .public) url_error=\(error.code.rawValue) latency_ms=\(latency)"
            )
            if error.code == .timedOut {
                throw AppError.timedOut
            }
            throw AppError.networkUnavailable
        } catch {
            let latency = elapsedMilliseconds(since: startedAt)
            KelinLog.api.error(
                "transport method=\(endpoint.method.rawValue, privacy: .public) endpoint=\(endpoint.path, privacy: .public) request_id=\(prepared.requestID, privacy: .public) error_code=NETWORK_UNAVAILABLE latency_ms=\(latency)"
            )
            throw AppError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkUnavailable
        }

        let latency = elapsedMilliseconds(since: startedAt)

        if httpResponse.statusCode == 401 {
            KelinLog.api.error(
                "response method=\(endpoint.method.rawValue, privacy: .public) endpoint=\(endpoint.path, privacy: .public) request_id=\(prepared.requestID, privacy: .public) http_status=401 error_code=UNAUTHENTICATED latency_ms=\(latency)"
            )
            throw AppError.unauthenticated
        }

        let envelope: APIEnvelope<T>
        do {
            envelope = try jsonDecoder.decode(APIEnvelope<T>.self, from: data)
        } catch {
            KelinLog.api.error(
                "decode_failed method=\(endpoint.method.rawValue, privacy: .public) endpoint=\(endpoint.path, privacy: .public) request_id=\(prepared.requestID, privacy: .public) http_status=\(httpResponse.statusCode) bytes=\(data.count) latency_ms=\(latency)"
            )
            throw AppError.decoding
        }

        if envelope.ok {
            guard let payload = envelope.data else {
                KelinLog.api.error(
                    "decode_failed method=\(endpoint.method.rawValue, privacy: .public) endpoint=\(endpoint.path, privacy: .public) request_id=\(envelope.requestID, privacy: .public) http_status=\(httpResponse.statusCode) error_code=MISSING_DATA latency_ms=\(latency)"
                )
                throw AppError.decoding
            }
            KelinLog.api.info(
                "response method=\(endpoint.method.rawValue, privacy: .public) endpoint=\(endpoint.path, privacy: .public) request_id=\(envelope.requestID, privacy: .public) http_status=\(httpResponse.statusCode) latency_ms=\(latency)"
            )
            return APISendResult(
                payload: payload,
                serverTime: envelope.serverTime,
                requestID: envelope.requestID
            )
        }

        if let errorPayload = envelope.error {
            let detailKeys = errorPayload.detailKeys.joined(separator: ",")
            KelinLog.api.error(
                "business_error method=\(endpoint.method.rawValue, privacy: .public) endpoint=\(endpoint.path, privacy: .public) request_id=\(envelope.requestID, privacy: .public) http_status=\(httpResponse.statusCode) error_code=\(errorPayload.code, privacy: .public) retryable=\(errorPayload.retryable) details_keys=\(detailKeys, privacy: .public) latency_ms=\(latency)"
            )
            throw APIErrorMapper.map(errorPayload, requestID: envelope.requestID)
        }

        KelinLog.api.error(
            "response method=\(endpoint.method.rawValue, privacy: .public) endpoint=\(endpoint.path, privacy: .public) request_id=\(envelope.requestID, privacy: .public) http_status=\(httpResponse.statusCode) error_code=UNKNOWN latency_ms=\(latency)"
        )
        throw AppError.unknown(requestID: envelope.requestID)
    }

    private func makeURLRequest(for endpoint: APIEndpoint) async throws -> PreparedRequest {
        let accessToken = try await auth.currentAccessToken()
        let url = try makeURL(for: endpoint.path)
        let requestID = UUID().uuidString.lowercased()

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.timeoutInterval = endpoint.timeout
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(requestID, forHTTPHeaderField: "X-Request-ID")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return PreparedRequest(request: request, requestID: requestID)
    }

    private func elapsedMilliseconds(since start: ContinuousClock.Instant) -> Int {
        let elapsed = ContinuousClock.now - start
        return Int(elapsed.components.seconds * 1_000 + elapsed.components.attoseconds / 1_000_000_000_000_000)
    }

    private func makeURL(for path: String) throws -> URL {
        guard path.hasPrefix("/") else {
            throw AppError.decoding
        }

        var base = config.apiBaseURL.absoluteString
        if base.hasSuffix("/") {
            base.removeLast()
        }

        guard let url = URL(string: "\(base)/api/v1\(path)") else {
            throw AppError.networkUnavailable
        }

        return url
    }
}

private struct PreparedRequest: Sendable {
    let request: URLRequest
    let requestID: String
}
