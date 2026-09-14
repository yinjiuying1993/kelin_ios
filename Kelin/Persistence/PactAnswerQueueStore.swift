import Foundation

enum PactQueueCodec {
    static func encode(_ state: PactQueueState) throws -> Data {
        try JSONEncoder().encode(state)
    }

    static func decode(_ data: Data) throws -> PactQueueState {
        try JSONDecoder().decode(PactQueueState.self, from: data)
    }
}

struct PactAnswerQueueStore: Sendable {
    private let localStore: LocalStore

    init(localStore: LocalStore) {
        self.localStore = localStore
    }

    func load(accountUserID: UUID) async throws -> PactQueueState {
        let drafts = try await localStore.fetchDrafts(accountUserID: accountUserID)
        guard let draft = drafts.first(where: { $0.kind == .pactAnswerQueue }) else {
            return PactQueueState(items: [], sessionID: nil, sessionDate: nil, sessionStatus: nil, rowVersion: nil, dayIndex: nil)
        }
        return try PactQueueCodec.decode(draft.payloadData)
    }

    func save(_ state: PactQueueState, accountUserID: UUID) async throws {
        let drafts = try await localStore.fetchDrafts(accountUserID: accountUserID)
        let existing = drafts.first(where: { $0.kind == .pactAnswerQueue })
        let record = DraftRecord(
            id: existing?.id ?? PactQueueDraftID.make(accountUserID: accountUserID),
            accountUserID: accountUserID,
            kind: .pactAnswerQueue,
            payloadData: try PactQueueCodec.encode(state),
            updatedAt: Date()
        )
        try await localStore.upsertDraft(record)
    }

    func enqueue(_ item: PactAnswerQueueItem, accountUserID: UUID) async throws {
        var state = try await load(accountUserID: accountUserID)
        if let index = state.items.firstIndex(where: { $0.questionID == item.questionID }) {
            state.items[index] = item
        } else {
            state.items.append(item)
        }
        state.items.sort { $0.order < $1.order }
        state.sessionID = item.sessionID
        try await save(state, accountUserID: accountUserID)
    }

    func remove(questionID: String, accountUserID: UUID) async throws {
        var state = try await load(accountUserID: accountUserID)
        state.items.removeAll { $0.questionID == questionID }
        try await save(state, accountUserID: accountUserID)
    }

    func next(accountUserID: UUID) async throws -> PactAnswerQueueItem? {
        try await load(accountUserID: accountUserID).items.sorted { $0.order < $1.order }.first
    }
}
