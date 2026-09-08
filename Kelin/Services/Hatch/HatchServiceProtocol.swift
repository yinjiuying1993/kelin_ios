import Foundation

protocol HatchServiceProtocol: Sendable {
    func createSpirit(_ request: CreateSpiritRequest) async throws -> CreateSpiritResult
}
