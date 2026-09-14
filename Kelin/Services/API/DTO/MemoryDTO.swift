import Foundation

enum MemoryDTOCoding {
    static func rejectUnknownKeys<Key: CodingKey>(
        in container: KeyedDecodingContainer<Key>,
        allowed: Set<String>,
        debugDescription: String
    ) throws {
        let extras = Set(container.allKeys.map(\.stringValue)).subtracting(allowed)
        guard extras.isEmpty else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "\(debugDescription): \(extras.sorted().joined(separator: ","))"
                )
            )
        }
    }
}

struct MemoryPublicDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let type: String
    let summary: String
    let tags: [String]
    let salience: Int
    let confidence: Double
    let status: String
    let version: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case summary
        case tags
        case salience
        case confidence
        case status
        case version
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try MemoryDTOCoding.rejectUnknownKeys(
            in: container,
            allowed: Set(CodingKeys.allCases.map(\.stringValue)),
            debugDescription: "unknown MemoryPublic field"
        )
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        summary = try container.decode(String.self, forKey: .summary)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        salience = try container.decode(Int.self, forKey: .salience)
        confidence = try container.decode(Double.self, forKey: .confidence)
        status = try container.decode(String.self, forKey: .status)
        version = try container.decode(Int.self, forKey: .version)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

extension MemoryPublicDTO.CodingKeys: CaseIterable {}

struct MemoryTombstoneDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let deletedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case deletedAt = "deleted_at"
        case summary
        case type
        case tags
        case salience
        case confidence
        case status
        case version
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.summary)
            || container.contains(.type)
            || container.contains(.tags)
            || container.contains(.salience)
            || container.contains(.confidence)
            || container.contains(.status)
            || container.contains(.version) {
            throw DecodingError.dataCorruptedError(
                forKey: .id,
                in: container,
                debugDescription: "tombstone must not include body fields"
            )
        }
        id = try container.decode(UUID.self, forKey: .id)
        deletedAt = try container.decode(Date.self, forKey: .deletedAt)
    }
}

struct MemoryPageDTO: Decodable, Sendable, Equatable {
    let items: [MemoryPublicDTO]
    let tombstones: [MemoryTombstoneDTO]
    let nextCursor: String?
    let hasMore: Bool
    let snapshotAt: Date

    enum CodingKeys: String, CodingKey {
        case items
        case tombstones
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
        case snapshotAt = "snapshot_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([MemoryPublicDTO].self, forKey: .items)
        tombstones = try container.decodeIfPresent([MemoryTombstoneDTO].self, forKey: .tombstones) ?? []
        nextCursor = try container.decodeIfPresent(String.self, forKey: .nextCursor)
        hasMore = try container.decode(Bool.self, forKey: .hasMore)
        snapshotAt = try container.decode(Date.self, forKey: .snapshotAt)
    }
}

struct MemoryPatchRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let expectedVersion: Int
    let action: String
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case expectedVersion = "expected_version"
        case action
        case summary
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clientID, forKey: .clientID)
        try container.encode(expectedVersion, forKey: .expectedVersion)
        try container.encode(action, forKey: .action)
        try container.encodeIfPresent(summary, forKey: .summary)
    }
}

struct MemoryDeleteRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let expectedVersion: Int

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case expectedVersion = "expected_version"
    }
}

struct MemoryClearRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let confirm: String

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case confirm
    }
}
