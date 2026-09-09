import Foundation

enum OnboardingConversationCodec {
    static func encode(_ messages: [OnboardingMessage]) throws -> Data {
        try JSONEncoder().encode(messages)
    }

    static func decode(_ data: Data) throws -> [OnboardingMessage] {
        try JSONDecoder().decode([OnboardingMessage].self, from: data)
    }
}

enum OnboardingConversationDraftID {
    static func make(accountUserID: UUID) -> UUID {
        var bytes = accountUserID.uuid
        bytes.6 = (bytes.6 & 0x0F) | 0x40
        bytes.8 = (bytes.8 & 0x3F) | 0x80
        return UUID(uuid: bytes)
    }
}
