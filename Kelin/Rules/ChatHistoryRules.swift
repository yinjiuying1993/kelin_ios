import Foundation

enum ChatHistoryRules {
    static func presentableMessages(from messages: [ChatMessage]) -> [ChatMessage] {
        stableSort(dedupeByIdentity(messages))
    }

    static func stableSort(_ messages: [ChatMessage]) -> [ChatMessage] {
        messages.sorted(by: isOrderedBefore)
    }

    static func dedupeByID(_ messages: [ChatMessage]) -> [ChatMessage] {
        dedupeByIdentity(messages)
    }

    static func dedupeByIdentity(_ messages: [ChatMessage]) -> [ChatMessage] {
        var deduped: [ChatMessage] = []
        for message in messages {
            if let index = deduped.firstIndex(where: { matches($0, message) }) {
                deduped[index] = preferredMessage(existing: deduped[index], incoming: message)
            } else {
                deduped.append(message)
            }
        }
        return deduped
    }

    static func merge(existing: [ChatMessage], remote: [ChatMessage]) -> [ChatMessage] {
        var merged = existing

        for remoteMessage in remote {
            if let index = merged.firstIndex(where: { matches($0, remoteMessage) }) {
                let preferred = preferredMessage(existing: merged[index], incoming: remoteMessage)
                merged[index] = preferred
            } else {
                merged.append(remoteMessage)
            }
        }

        return presentableMessages(from: merged)
    }

    static func matches(_ lhs: ChatMessage, _ rhs: ChatMessage) -> Bool {
        if lhs.id == rhs.id {
            return true
        }
        return lhs.role == .user && rhs.role == .user && lhs.clientID == rhs.clientID
    }

    static func makeRecord(
        _ message: ChatMessage,
        accountUserID: UUID
    ) throws -> CachedMessageRecord {
        CachedMessageRecord(
            id: message.id,
            accountUserID: accountUserID,
            clientID: message.clientID,
            payloadData: try MessageCodec.encode(message),
            sendState: sendState(for: message.status),
            createdAt: message.createdAt
        )
    }

    static func sendState(for status: ChatMessage.Status) -> CachedMessageSendState {
        switch status {
        case .queued, .sending:
            return .queued
        case .accepted, .generated:
            return .sent
        case .failed:
            return .failed
        }
    }

    static func isOrderedBefore(_ lhs: ChatMessage, _ rhs: ChatMessage) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.clientID.uuidString.lowercased() < rhs.clientID.uuidString.lowercased()
    }

    private static func preferredMessage(existing: ChatMessage, incoming: ChatMessage) -> ChatMessage {
        if isSettled(existing) != isSettled(incoming) {
            return isSettled(incoming) ? incoming : existing
        }
        if shouldPreferLocal(existing) {
            return existing
        }
        if shouldPreferLocal(incoming) {
            return incoming
        }
        return incoming
    }

    private static func isSettled(_ message: ChatMessage) -> Bool {
        switch message.status {
        case .accepted, .generated:
            return true
        case .queued, .sending, .failed:
            return false
        }
    }

    private static func shouldPreferLocal(_ message: ChatMessage) -> Bool {
        switch message.status {
        case .queued, .sending, .failed:
            return true
        case .accepted, .generated:
            return false
        }
    }
}
