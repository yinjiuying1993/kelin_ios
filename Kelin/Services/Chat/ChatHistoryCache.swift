import Foundation

struct ChatHistoryCache: Sendable {
    private let localStore: LocalStore

    init(localStore: LocalStore) {
        self.localStore = localStore
    }

    func loadCachedMessages(accountUserID: UUID) async throws -> [ChatMessage] {
        let records = try await localStore.fetchMessages(accountUserID: accountUserID)
        let decoded = try records.compactMap { record -> ChatMessage? in
            do {
                return try MessageCodec.decode(record.payloadData)
            } catch {
                return nil
            }
        }
        return ChatHistoryRules.presentableMessages(from: decoded)
    }

    func persistMessages(_ messages: [ChatMessage], accountUserID: UUID) async throws {
        let normalized = ChatHistoryRules.presentableMessages(from: messages)
        let keptIDs = Set(normalized.map(\.id))
        let settledUserClientIDs = Set(
            normalized.compactMap { message -> UUID? in
                guard message.role == .user else { return nil }
                switch message.status {
                case .accepted, .generated:
                    return message.clientID
                case .queued, .sending, .failed:
                    return nil
                }
            }
        )

        for message in normalized {
            try await localStore.upsertMessage(
                try ChatHistoryRules.makeRecord(message, accountUserID: accountUserID)
            )
        }

        let stored = try await localStore.fetchMessages(accountUserID: accountUserID)
        for record in stored where record.sendState == .queued {
            let isReplacedOutbound = settledUserClientIDs.contains(record.clientID) && !keptIDs.contains(record.id)
            if isReplacedOutbound {
                try await localStore.deleteMessage(id: record.id, accountUserID: accountUserID)
            }
        }
    }

    func mergeRemotePage(into cached: [ChatMessage], page: MessagesPage) -> [ChatMessage] {
        ChatHistoryRules.merge(existing: cached, remote: page.items)
    }

    func applyMergedMessages(_ messages: [ChatMessage], accountUserID: UUID) async throws {
        try await persistMessages(messages, accountUserID: accountUserID)
    }
}
