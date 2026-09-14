import Foundation

protocol MemoryServiceProtocol: Sendable {
    func list(filter: MemoryFilter, cursor: String?, limit: Int) async throws -> MemoryPage
    func correct(
        id: UUID,
        expectedVersion: Int,
        summary: String,
        clientID: UUID
    ) async throws -> MemoryMutation
    func seal(id: UUID, expectedVersion: Int, clientID: UUID) async throws -> MemoryMutation
    func delete(id: UUID, expectedVersion: Int, clientID: UUID) async throws -> MemoryMutation
    func clearAll(clientID: UUID) async throws -> MemoryMutation
}
