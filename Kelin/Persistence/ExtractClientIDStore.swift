import Foundation

struct ExtractStableIDs: Codable, Equatable, Sendable {
    var clientIDsByWindow: [String: UUID]
}

enum ExtractStableIDsCodec {
    static func encode(_ ids: ExtractStableIDs) throws -> Data {
        try JSONEncoder().encode(ids)
    }

    static func decode(_ data: Data) throws -> ExtractStableIDs {
        try JSONDecoder().decode(ExtractStableIDs.self, from: data)
    }
}

enum ExtractStableIDsDraftID {
    static func make(accountUserID: UUID) -> UUID {
        var bytes = accountUserID.uuid
        bytes.0 = bytes.0 &+ 1
        bytes.1 = ~bytes.1
        bytes.6 = (bytes.6 & 0x0F) | 0x60
        bytes.8 = (bytes.8 & 0x3F) | 0x80
        return UUID(uuid: bytes)
    }
}

struct ExtractClientIDStore: Sendable {
    private let localStore: LocalStore

    init(localStore: LocalStore) {
        self.localStore = localStore
    }

    func clientID(for windowID: UUID, accountUserID: UUID) async throws -> UUID {
        var stored = try await load(accountUserID: accountUserID) ?? ExtractStableIDs(clientIDsByWindow: [:])
        let key = windowID.uuidString.lowercased()
        if let existing = stored.clientIDsByWindow[key] {
            return existing
        }

        let created = UUID()
        stored.clientIDsByWindow[key] = created
        try await persist(stored, accountUserID: accountUserID)
        return created
    }

    private func persist(_ ids: ExtractStableIDs, accountUserID: UUID) async throws {
        let existing = try await loadDraft(accountUserID: accountUserID)
        let record = DraftRecord(
            id: existing?.id ?? ExtractStableIDsDraftID.make(accountUserID: accountUserID),
            accountUserID: accountUserID,
            kind: .extractStableIDs,
            payloadData: try ExtractStableIDsCodec.encode(ids),
            updatedAt: Date()
        )
        try await localStore.upsertDraft(record)
    }

    private func load(accountUserID: UUID) async throws -> ExtractStableIDs? {
        guard let draft = try await loadDraft(accountUserID: accountUserID) else {
            return nil
        }
        return try ExtractStableIDsCodec.decode(draft.payloadData)
    }

    private func loadDraft(accountUserID: UUID) async throws -> DraftRecord? {
        let drafts = try await localStore.fetchDrafts(accountUserID: accountUserID)
        return drafts.first(where: { $0.kind == .extractStableIDs })
    }
}
