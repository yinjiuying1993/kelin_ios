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

struct OnboardingStableIDs: Codable, Equatable, Sendable {
    var spiritClientID: UUID?
    var chatClientMessageID: UUID?
    var chatContent: String?
    var completeClientID: UUID?

    var isEmpty: Bool {
        spiritClientID == nil
            && chatClientMessageID == nil
            && chatContent == nil
            && completeClientID == nil
    }
}

enum OnboardingStableIDsCodec {
    static func encode(_ ids: OnboardingStableIDs) throws -> Data {
        try JSONEncoder().encode(ids)
    }

    static func decode(_ data: Data) throws -> OnboardingStableIDs {
        try JSONDecoder().decode(OnboardingStableIDs.self, from: data)
    }
}

enum OnboardingStableIDsDraftID {
    static func make(accountUserID: UUID) -> UUID {
        var bytes = accountUserID.uuid
        bytes.0 = ~bytes.0
        bytes.1 = ~bytes.1
        bytes.2 = ~bytes.2
        bytes.3 = ~bytes.3
        bytes.6 = (bytes.6 & 0x0F) | 0x50
        bytes.8 = (bytes.8 & 0x3F) | 0x80
        return UUID(uuid: bytes)
    }
}
