import Foundation

struct MockAPIResponse: Sendable {
    let data: Data
    let statusCode: Int
}

actor MockAPIClient: APIClientProtocol {
    private var responsesByPath: [String: MockAPIResponse] = [:]
    private var errorByPath: [String: AppError] = [:]
    private(set) var requestedPaths: [String] = []

    func setResponse(_ response: MockAPIResponse, forPath path: String) {
        responsesByPath[path] = response
        errorByPath[path] = nil
    }

    func setError(_ error: AppError, forPath path: String) {
        errorByPath[path] = error
        responsesByPath[path] = nil
    }

    func send<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        requestedPaths.append(endpoint.path)

        if let error = errorByPath[endpoint.path] {
            throw error
        }

        guard let response = responsesByPath[endpoint.path] else {
            throw AppError.networkUnavailable
        }

        guard (200 ... 299).contains(response.statusCode) else {
            if response.statusCode == 401 {
                throw AppError.unauthenticated
            }
            throw AppError.unknown(requestID: "mock-request-id")
        }

        let decoder = APIDecoding.makeJSONDecoder()
        let envelope = try decoder.decode(APIEnvelope<T>.self, from: response.data)

        guard envelope.ok, let payload = envelope.data else {
            if let errorPayload = envelope.error {
                throw APIErrorMapper.map(errorPayload, requestID: envelope.requestID)
            }
            throw AppError.decoding
        }

        return payload
    }
}
