import Foundation

struct P16P20StableIDs: Codable, Equatable, Sendable {
    var clientIDsByKey: [String: UUID]
}

enum P16P20StableIDsCodec {
    static func encode(_ ids: P16P20StableIDs) throws -> Data {
        try JSONEncoder().encode(ids)
    }

    static func decode(_ data: Data) throws -> P16P20StableIDs {
        try JSONDecoder().decode(P16P20StableIDs.self, from: data)
    }
}

enum P16P20StableIDsDraftID {
    static func make(accountUserID: UUID) -> UUID {
        var bytes = accountUserID.uuid
        bytes.0 = bytes.0 &+ 5
        bytes.1 = ~bytes.1
        bytes.6 = (bytes.6 & 0x0F) | 0x60
        bytes.8 = (bytes.8 & 0x3F) | 0x80
        return UUID(uuid: bytes)
    }
}

struct P16P20ClientIDStore: Sendable {
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

    func forget(key: String, accountUserID: UUID) async throws {
        var stored = try await load(accountUserID: accountUserID)
        stored.clientIDsByKey.removeValue(forKey: key)
        try await persist(stored, accountUserID: accountUserID)
    }

    static func addFriendKey(_ inviteCode: String) -> String {
        "social.add:\(inviteCode)"
    }

    static func removeFriendKey(_ friendID: UUID) -> String {
        "social.remove:\(friendID.uuidString.lowercased())"
    }

    static func postcardReadKey(_ postcardID: UUID) -> String {
        "social.read:\(postcardID.uuidString.lowercased())"
    }

    static let settingsNameKey = "settings.name"
    static let settingsTTSKey = "settings.tts_on"
    static let settingsPushKey = "settings.push_on"
    static let settingsVisitKey = "settings.visit_on"
    static let settingsLocationKey = "settings.location_weather_on"
    static let settingsSearchKey = "settings.remote_search_on"
    static let settingsDNDKey = "settings.dnd"
    static let settingsDeleteAccountKey = "settings.delete_account"

    static func reportLineKey(_ reportID: UUID) -> String {
        "report.line:\(reportID.uuidString.lowercased())"
    }

    private func persist(_ ids: P16P20StableIDs, accountUserID: UUID) async throws {
        let existing = try await loadDraft(accountUserID: accountUserID)
        let record = DraftRecord(
            id: existing?.id ?? P16P20StableIDsDraftID.make(accountUserID: accountUserID),
            accountUserID: accountUserID,
            kind: .p16p20StableIDs,
            payloadData: try P16P20StableIDsCodec.encode(ids),
            updatedAt: Date()
        )
        try await localStore.upsertDraft(record)
    }

    private func load(accountUserID: UUID) async throws -> P16P20StableIDs {
        guard let draft = try await loadDraft(accountUserID: accountUserID) else {
            return P16P20StableIDs(clientIDsByKey: [:])
        }
        return try P16P20StableIDsCodec.decode(draft.payloadData)
    }

    private func loadDraft(accountUserID: UUID) async throws -> DraftRecord? {
        let drafts = try await localStore.fetchDrafts(accountUserID: accountUserID)
        return drafts.first(where: { $0.kind == .p16p20StableIDs })
    }
}
