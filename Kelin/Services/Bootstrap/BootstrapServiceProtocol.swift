import Foundation

protocol BootstrapServiceProtocol: Sendable {
    func fetchBootstrap() async throws -> BootstrapSnapshot
}
