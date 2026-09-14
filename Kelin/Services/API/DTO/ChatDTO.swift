import Foundation

struct ChatContextDTO: Codable, Sendable, Equatable {
    let timezone: String
    let localHour: Int
    let weather: String
    let city: String?

    enum CodingKeys: String, CodingKey {
        case timezone
        case localHour = "local_hour"
        case weather
        case city
    }
}

struct ChatRequestDTO: Codable, Sendable, Equatable {
    let clientMessageID: UUID
    let content: String
    let source: String
    let onboarding: Bool
    let context: ChatContextDTO

    enum CodingKeys: String, CodingKey {
        case clientMessageID = "client_message_id"
        case content
        case source
        case onboarding
        case context
    }
}

struct ChatMessageDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let content: String
    let clientID: UUID?
    let sourceRefs: [MessageSourceRefDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case clientID = "client_id"
        case sourceRefs = "source_refs"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        clientID = try container.decodeIfPresent(UUID.self, forKey: .clientID)
        sourceRefs = try container.decodeIfPresent([MessageSourceRefDTO].self, forKey: .sourceRefs) ?? []
    }
}

struct ChatUsageDTO: Decodable, Sendable, Equatable {
    let inputUnits: Int
    let outputUnits: Int

    enum CodingKeys: String, CodingKey {
        case inputUnits = "input_units"
        case outputUnits = "output_units"
    }
}

struct ChatTurnResourceDTO: Decodable, Sendable, Equatable {
    let type: String
    let userMessage: ChatMessageDTO
    let spiritMessage: ChatMessageDTO
    let conversationWindowID: UUID
    let shouldExtract: Bool
    let usage: ChatUsageDTO
    let generationSource: String?

    enum CodingKeys: String, CodingKey {
        case type
        case userMessage = "user_message"
        case spiritMessage = "spirit_message"
        case conversationWindowID = "conversation_window_id"
        case shouldExtract = "should_extract"
        case usage
        case generationSource = "generation_source"
    }
}

struct ChatMutationResultDTO: Decodable, Sendable, Equatable {
    let resource: ChatTurnResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
}
