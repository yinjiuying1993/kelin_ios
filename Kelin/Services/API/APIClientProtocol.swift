import Foundation

protocol APIClientProtocol: Sendable {
    func send<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T
}
