import Foundation

struct PactStableIDs: Codable, Equatable, Sendable {
    var clientIDsByKey: [String: UUID]
}

enum PactStableIDsCodec {
    static func encode(_ ids: PactStableIDs) throws -> Data {
        try JSONEncoder().encode(ids)
    }

    static func decode(_ data: Data) throws -> PactStableIDs {
        try JSONDecoder().decode(PactStableIDs.self, from: data)
    }
}

struct PactClientIDStore: Sendable {
    private let localStore: LocalStore

    init(localStore: LocalStore) {
        self.localStore = localStore
    }

    func clientID(for key: String, accountUserID: UUID) async throws -> UUID {
        var stored = try await load(accountUserID: accountUserID)
        if let existing = stored.clientIDsByKey[key] {
            return existing
        }

        let created = UUID()
        stored.clientIDsByKey[key] = created
        try await persist(stored, accountUserID: accountUserID)
        return created
    }

    static func createKey(pactTheme: String) -> String { "create:\(pactTheme)" }
    static func sessionKey(pactID: UUID, day: String) -> String {
        "session:\(pactID.uuidString.lowercased()):\(day)"
    }
    static func skipKey(pactID: UUID, day: String) -> String {
        "skip:\(pactID.uuidString.lowercased()):\(day)"
    }
    static func answerKey(sessionID: UUID, questionID: String) -> String {
        "answer:\(sessionID.uuidString.lowercased()):\(questionID)"
    }

    private func persist(_ ids: PactStableIDs, accountUserID: UUID) async throws {
        let existing = try await loadDraft(accountUserID: accountUserID)
        let record = DraftRecord(
            id: existing?.id ?? PactStableIDsDraftID.make(accountUserID: accountUserID),
            accountUserID: accountUserID,
            kind: .pactStableIDs,
            payloadData: try PactStableIDsCodec.encode(ids),
            updatedAt: Date()
        )
        try await localStore.upsertDraft(record)
    }

    private func load(accountUserID: UUID) async throws -> PactStableIDs {
        guard let draft = try await loadDraft(accountUserID: accountUserID) else {
            return PactStableIDs(clientIDsByKey: [:])
        }
        return try PactStableIDsCodec.decode(draft.payloadData)
    }

    private func loadDraft(accountUserID: UUID) async throws -> DraftRecord? {
        let drafts = try await localStore.fetchDrafts(accountUserID: accountUserID)
        return drafts.first(where: { $0.kind == .pactStableIDs })
    }
}
