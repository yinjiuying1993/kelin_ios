import Foundation

struct ChatSendContext: Equatable, Sendable, Codable {
    let timezone: String
    let localHour: Int
    let weather: String
    let city: String?

    static func make(
        weather: String?,
        city: String? = nil,
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> ChatSendContext {
        let calendar = Calendar.current
        let hour = calendar.dateComponents(in: timeZone, from: now).hour ?? 0
        return ChatSendContext(
            timezone: timeZone.identifier,
            localHour: hour,
            weather: weather ?? "unknown",
            city: city
        )
    }
}

struct ChatSendPayload: Equatable, Sendable, Codable {
    let messageID: UUID
    let clientMessageID: UUID
    let content: String
    let context: ChatSendContext
}

struct ChatTurnResult: Equatable, Sendable {
    let userMessage: ChatMessage
    let spiritMessage: ChatMessage
    let conversationWindowID: UUID
    let shouldExtract: Bool
    let usesStubProvider: Bool
    let patch: SessionPatch
}

enum ChatGenerationState: Equatable, Sendable {
    case idle
    case generating(clientMessageID: UUID)
}
