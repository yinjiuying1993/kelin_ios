import Foundation

struct FeedStableIDs: Codable, Equatable, Sendable {
    var clientIDsByKey: [String: UUID]
    var activePromiseID: UUID?
    var activePromiseText: String?
    var activePromiseRemindAt: Date?
}

enum FeedStableIDsCodec {
    static func encode(_ ids: FeedStableIDs) throws -> Data {
        try JSONEncoder().encode(ids)
    }

    static func decode(_ data: Data) throws -> FeedStableIDs {
        try JSONDecoder().decode(FeedStableIDs.self, from: data)
    }
}

enum FeedStableIDsDraftID {
    static func make(accountUserID: UUID) -> UUID {
        var bytes = accountUserID.uuid
        bytes.0 = bytes.0 &+ 3
        bytes.1 = ~bytes.1
        bytes.6 = (bytes.6 & 0x0F) | 0x60
        bytes.8 = (bytes.8 & 0x3F) | 0x80
        return UUID(uuid: bytes)
    }
}

struct FeedClientIDStore: Sendable {
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

    func rememberPromise(
        id: UUID,
        text: String,
        remindAt: Date,
        accountUserID: UUID
    ) async throws {
        var stored = try await load(accountUserID: accountUserID)
        stored.activePromiseID = id
        stored.activePromiseText = text
        stored.activePromiseRemindAt = remindAt
        try await persist(stored, accountUserID: accountUserID)
    }

    func clearPromise(accountUserID: UUID) async throws {
        var stored = try await load(accountUserID: accountUserID)
        stored.activePromiseID = nil
        stored.activePromiseText = nil
        stored.activePromiseRemindAt = nil
        try await persist(stored, accountUserID: accountUserID)
    }

    func load(accountUserID: UUID) async throws -> FeedStableIDs {
        guard let draft = try await loadDraft(accountUserID: accountUserID) else {
            return FeedStableIDs(clientIDsByKey: [:])
        }
        return try FeedStableIDsCodec.decode(draft.payloadData)
    }

    static let foodKey = "food"
    static let knowledgeKey = "knowledge"
    static let emotionKey = "emotion"
    static let promiseCreateKey = "promise.create"
    static let promisePatchKey = "promise.patch"
    static let promiseCompleteKey = "promise.complete"
    static let promiseCancelKey = "promise.cancel"
    static let sightLocationKey = "sight.location"
    static let sightPhotoFeedKey = "sight.photo.feed"
    static let sightPhotoUploadKey = "sight.photo.upload"
    static let sightPhotoModerateKey = "sight.photo.moderate"

    private func persist(_ ids: FeedStableIDs, accountUserID: UUID) async throws {
        let existing = try await loadDraft(accountUserID: accountUserID)
        let record = DraftRecord(
            id: existing?.id ?? FeedStableIDsDraftID.make(accountUserID: accountUserID),
            accountUserID: accountUserID,
            kind: .feedStableIDs,
            payloadData: try FeedStableIDsCodec.encode(ids),
            updatedAt: Date()
        )
        try await localStore.upsertDraft(record)
    }

    private func loadDraft(accountUserID: UUID) async throws -> DraftRecord? {
        let drafts = try await localStore.fetchDrafts(accountUserID: accountUserID)
        return drafts.first(where: { $0.kind == .feedStableIDs })
    }
}
