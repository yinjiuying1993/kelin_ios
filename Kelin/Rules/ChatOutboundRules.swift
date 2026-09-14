import Foundation

enum ChatOutboundRules {
    static let maxQueuedCount = 3
    static let maxContentLength = 4_000

    static func canAcceptSubmission(messages: [ChatMessage]) -> Bool {
        queuedUserMessageCount(messages) < maxQueuedCount
    }

    static func queuedUserMessageCount(_ messages: [ChatMessage]) -> Int {
        messages.filter { $0.role == .user && $0.status == .queued }.count
    }

    static func hasInFlight(messages: [ChatMessage]) -> Bool {
        messages.contains { $0.role == .user && $0.status == .sending }
    }

    static func normalizeInterruptedOutbound(_ messages: [ChatMessage]) -> [ChatMessage] {
        messages.map { message in
            guard message.role == .user, message.status == .sending else {
                return message
            }
            return message.with(status: .queued)
        }
    }

    static func nextSendableMessage(in messages: [ChatMessage]) -> ChatMessage? {
        ChatHistoryRules.stableSort(messages).first { message in
            message.role == .user && message.status == .queued
        }
    }

    static func validateContent(_ raw: String) throws -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.invalidInput
        }
        guard trimmed.count <= maxContentLength else {
            throw AppError.invalidInput
        }
        return trimmed
    }

    static func makeOutboundUserMessage(
        clientMessageID: UUID,
        content: String,
        createdAt: Date,
        status: ChatMessage.Status = .queued,
        source: ChatMessage.Source = .text
    ) -> ChatMessage {
        ChatMessage(
            id: clientMessageID,
            clientID: clientMessageID,
            role: .user,
            content: content,
            source: source,
            status: status,
            createdAt: createdAt
        )
    }

    static func makePendingOperation(
        accountUserID: UUID,
        payload: ChatSendPayload,
        createdAt: Date
    ) throws -> PendingOperationRecord {
        PendingOperationRecord(
            id: payload.messageID,
            accountUserID: accountUserID,
            kind: .chat,
            clientID: payload.clientMessageID,
            payloadData: try ChatSendPayloadCodec.encode(payload),
            createdAt: createdAt,
            attemptCount: 0,
            nextRetryAt: nil,
            lastErrorCode: nil,
            state: .pending
        )
    }
}
