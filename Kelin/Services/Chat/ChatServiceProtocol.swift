import Foundation

protocol ChatServiceProtocol: Sendable {
    func sendMessage(
        clientMessageID: UUID,
        content: String,
        context: ChatSendContext,
        source: ChatMessage.Source
    ) async throws -> ChatTurnResult
}
