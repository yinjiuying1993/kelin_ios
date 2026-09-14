import Foundation

enum ChatSendPayloadCodec {
    static func encode(_ payload: ChatSendPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    static func decode(_ data: Data) throws -> ChatSendPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ChatSendPayload.self, from: data)
    }
}
