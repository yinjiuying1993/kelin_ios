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
        let request = try await makeURLRequest(for: endpoint)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await urlSession.data(for: request)
        } catch is CancellationError {
            throw AppError.cancelled
        } catch let error as URLError where error.code == .timedOut {
            throw AppError.timedOut
        } catch URLError.notConnectedToInternet, URLError.networkConnectionLost {
            throw AppError.networkUnavailable
        } catch {
            throw AppError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkUnavailable
        }

        if httpResponse.statusCode == 401 {
            throw AppError.unauthenticated
        }

        let envelope: APIEnvelope<T>
        do {
            envelope = try jsonDecoder.decode(APIEnvelope<T>.self, from: data)
        } catch {
            throw AppError.decoding
        }

        if envelope.ok {
            guard let payload = envelope.data else {
                throw AppError.decoding
            }
            return APISendResult(
                payload: payload,
                serverTime: envelope.serverTime,
                requestID: envelope.requestID
            )
        }

        if let errorPayload = envelope.error {
            throw APIErrorMapper.map(errorPayload, requestID: envelope.requestID)
        }

        throw AppError.unknown(requestID: envelope.requestID)
    }

    private func makeURLRequest(for endpoint: APIEndpoint) async throws -> URLRequest {
        let accessToken = try await auth.currentAccessToken()
        let url = try makeURL(for: endpoint.path)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.timeoutInterval = endpoint.timeout
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(UUID().uuidString.lowercased(), forHTTPHeaderField: "X-Request-ID")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
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
