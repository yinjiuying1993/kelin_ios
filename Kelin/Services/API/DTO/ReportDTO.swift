import Foundation

struct ReportCardSpiritDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let name: String
    let stage: String
    let publicLayers: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case stage
        case publicLayers = "public_layers"
    }
}

struct ReportTopTraitDTO: Decodable, Sendable, Equatable {
    let dimension: String
    let value: Int
}

struct ReportCardMemoryDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let type: String?
    let summary: String?
    let unavailable: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case summary
        case unavailable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        unavailable = try container.decode(Bool.self, forKey: .unavailable)
        if unavailable {
            type = nil
            summary = nil
        } else {
            type = try container.decodeIfPresent(String.self, forKey: .type)
            summary = try container.decodeIfPresent(String.self, forKey: .summary)
        }
    }
}

struct ReportCardDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let status: String
    let rulesVersion: String
    let title: String
    let spirit: ReportCardSpiritDTO
    let roomWeather: String
    let topTraits: [ReportTopTraitDTO]
    let topMemories: [ReportCardMemoryDTO]
    let scholarMarks: [String]
    let signatureLine: String?
    let inviteCode: String
    let generatedAt: Date
    let version: Int

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case rulesVersion = "rules_version"
        case title
        case spirit
        case roomWeather = "room_weather"
        case topTraits = "top_traits"
        case topMemories = "top_memories"
        case scholarMarks = "scholar_marks"
        case signatureLine = "signature_line"
        case inviteCode = "invite_code"
        case generatedAt = "generated_at"
        case version
    }
}

struct ReportLineRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let reportID: UUID
    let expectedVersion: Int

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case reportID = "report_id"
        case expectedVersion = "expected_version"
    }
}

struct ReportLineResultDTO: Decodable, Sendable, Equatable {
    let resource: ReportCardDTO
    let patch: SessionPatchDTO
}
