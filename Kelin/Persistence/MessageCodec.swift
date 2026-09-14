import Foundation

enum MessageCodec {
    static func encode(_ message: ChatMessage) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(message)
    }

    static func decode(_ data: Data) throws -> ChatMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ChatMessage.self, from: data)
    }
}
