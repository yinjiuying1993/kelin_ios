import Foundation

struct MessagesPageDTO: Decodable, Sendable, Equatable {
    let items: [MessageItemDTO]
    let nextCursor: String?
    let hasMore: Bool
    let snapshotAt: Date

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
        case snapshotAt = "snapshot_at"
    }
}

struct MessageItemDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let clientID: UUID?
    let role: String
    let content: String
    let source: String
    let status: String
    let replyToMessageID: UUID?
    let sourceRefs: [MessageSourceRefDTO]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case clientID = "client_id"
        case role
        case content
        case source
        case status
        case replyToMessageID = "reply_to_message_id"
        case sourceRefs = "source_refs"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        clientID = try container.decodeIfPresent(UUID.self, forKey: .clientID)
        role = try container.decode(String.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        source = try container.decode(String.self, forKey: .source)
        status = try container.decode(String.self, forKey: .status)
        replyToMessageID = try container.decodeIfPresent(UUID.self, forKey: .replyToMessageID)
        sourceRefs = try container.decodeIfPresent([MessageSourceRefDTO].self, forKey: .sourceRefs) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct MessageSourceRefDTO: Decodable, Sendable, Equatable {
    let type: String
    let id: UUID?
    let url: String?
    let fetchedAt: Date?
    let title: String?

    enum CodingKeys: String, CodingKey {
        case type
        case kind
        case id
        case url
        case fetchedAt = "fetched_at"
        case title
        case memoryID = "memory_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawType = try container.decodeIfPresent(String.self, forKey: .type)
            ?? container.decodeIfPresent(String.self, forKey: .kind)
        guard let rawType, !rawType.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "source_ref missing type"
            )
        }
        type = rawType
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
            ?? container.decodeIfPresent(UUID.self, forKey: .memoryID)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        fetchedAt = try container.decodeIfPresent(Date.self, forKey: .fetchedAt)
        title = try container.decodeIfPresent(String.self, forKey: .title)
    }
}
