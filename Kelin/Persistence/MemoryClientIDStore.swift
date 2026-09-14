import Foundation

struct MemoryStableIDs: Codable, Equatable, Sendable {
    var clientIDsByKey: [String: UUID]
}

enum MemoryStableIDsCodec {
    static func encode(_ ids: MemoryStableIDs) throws -> Data {
        try JSONEncoder().encode(ids)
    }

    static func decode(_ data: Data) throws -> MemoryStableIDs {
        try JSONDecoder().decode(MemoryStableIDs.self, from: data)
    }
}

enum MemoryStableIDsDraftID {
    static func make(accountUserID: UUID) -> UUID {
        var bytes = accountUserID.uuid
        bytes.0 = bytes.0 &+ 2
        bytes.1 = ~bytes.1
        bytes.6 = (bytes.6 & 0x0F) | 0x60
        bytes.8 = (bytes.8 & 0x3F) | 0x80
        return UUID(uuid: bytes)
    }
}

struct MemoryClientIDStore: Sendable {
    private let localStore: LocalStore

    init(localStore: LocalStore) {
        self.localStore = localStore
    }

    func clientID(for key: String, accountUserID: UUID) async throws -> UUID {
        var stored = try await load(accountUserID: accountUserID) ?? MemoryStableIDs(clientIDsByKey: [:])
        if let existing = stored.clientIDsByKey[key] {
            return existing
        }

        let created = UUID()
        stored.clientIDsByKey[key] = created
        try await persist(stored, accountUserID: accountUserID)
        return created
    }

    func forget(key: String, accountUserID: UUID) async throws {
        var stored = try await load(accountUserID: accountUserID) ?? MemoryStableIDs(clientIDsByKey: [:])
        stored.clientIDsByKey.removeValue(forKey: key)
        try await persist(stored, accountUserID: accountUserID)
    }

    static func correctKey(_ id: UUID) -> String { "correct:\(id.uuidString.lowercased())" }
    static func sealKey(_ id: UUID) -> String { "seal:\(id.uuidString.lowercased())" }
    static func deleteKey(_ id: UUID) -> String { "delete:\(id.uuidString.lowercased())" }
    static let clearKey = "clear:all"

    private func persist(_ ids: MemoryStableIDs, accountUserID: UUID) async throws {
        let existing = try await loadDraft(accountUserID: accountUserID)
        let record = DraftRecord(
            id: existing?.id ?? MemoryStableIDsDraftID.make(accountUserID: accountUserID),
            accountUserID: accountUserID,
            kind: .memoryStableIDs,
            payloadData: try MemoryStableIDsCodec.encode(ids),
            updatedAt: Date()
        )
        try await localStore.upsertDraft(record)
    }

    private func load(accountUserID: UUID) async throws -> MemoryStableIDs? {
        guard let draft = try await loadDraft(accountUserID: accountUserID) else {
            return nil
        }
        return try MemoryStableIDsCodec.decode(draft.payloadData)
    }

    private func loadDraft(accountUserID: UUID) async throws -> DraftRecord? {
        let drafts = try await localStore.fetchDrafts(accountUserID: accountUserID)
        return drafts.first(where: { $0.kind == .memoryStableIDs })
    }
}
