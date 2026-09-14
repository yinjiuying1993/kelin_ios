import Foundation

struct ExtractRequestDTO: Codable, Sendable, Equatable {
    let clientID: UUID
    let conversationWindowID: UUID

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case conversationWindowID = "conversation_window_id"
    }
}

struct ExtractResourceDTO: Decodable, Sendable, Equatable {
    let status: String
    let memories: [MemorySummaryDTO]
    let styleSamples: [ExtractStyleSampleDTO]

    enum CodingKeys: String, CodingKey {
        case status
        case memories
        case styleSamples = "style_samples"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "extracted"
        memories = try container.decodeIfPresent([MemorySummaryDTO].self, forKey: .memories) ?? []
        styleSamples = try container.decodeIfPresent([ExtractStyleSampleDTO].self, forKey: .styleSamples) ?? []
    }
}

struct ExtractStyleSampleDTO: Decodable, Sendable, Equatable {
    let kind: String?
    let text: String?
}

struct ExtractMutationResultDTO: Decodable, Sendable, Equatable {
    let resource: ExtractResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
}
