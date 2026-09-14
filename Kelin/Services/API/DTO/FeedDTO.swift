import Foundation

struct FeedEmptyPayloadDTO: Encodable, Sendable, Equatable {}

struct FeedFoodRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let kind = "food"
    let payload = FeedEmptyPayloadDTO()

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case kind
        case payload
    }
}

struct FeedKnowledgePayloadDTO: Encodable, Sendable, Equatable {
    let text: String
}

struct FeedKnowledgeRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let kind = "knowledge"
    let payload: FeedKnowledgePayloadDTO

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case kind
        case payload
    }
}

struct FeedEmotionPayloadDTO: Encodable, Sendable, Equatable {
    let emotion: String
    let note: String?

    enum CodingKeys: String, CodingKey {
        case emotion
        case note
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(emotion, forKey: .emotion)
        try container.encodeIfPresent(note, forKey: .note)
    }
}

struct FeedEmotionRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let kind = "emotion"
    let payload: FeedEmotionPayloadDTO

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case kind
        case payload
    }
}

struct FeedPromisePayloadDTO: Encodable, Sendable, Equatable {
    let text: String
    let remindAt: Date

    enum CodingKeys: String, CodingKey {
        case text
        case remindAt = "remind_at"
    }
}

struct FeedPromiseRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let kind = "promise"
    let payload: FeedPromisePayloadDTO

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case kind
        case payload
    }
}

struct FeedSightPhotoPayloadDTO: Encodable, Sendable, Equatable {
    let source = "photo"
}

struct FeedSightPhotoRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let kind = "sight"
    let payload = FeedSightPhotoPayloadDTO()

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case kind
        case payload
    }
}

struct FeedSightLocationPayloadDTO: Encodable, Sendable, Equatable {
    let source = "location"
    let label: String
    let city: String
    let category: String?

    enum CodingKeys: String, CodingKey {
        case source
        case label
        case city
        case category
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encode(label, forKey: .label)
        try container.encode(city, forKey: .city)
        try container.encodeIfPresent(category, forKey: .category)
    }
}

struct FeedSightLocationRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let kind = "sight"
    let payload: FeedSightLocationPayloadDTO

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case kind
        case payload
    }
}

struct FeedPromisePatchRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let expectedVersion: Int
    let text: String
    let remindAt: Date

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case expectedVersion = "expected_version"
        case text
        case remindAt = "remind_at"
    }
}

struct FeedPromiseActionRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let expectedVersion: Int

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case expectedVersion = "expected_version"
    }
}

struct SightUploadURLRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let feedID: UUID
    let mimeType = "image/jpeg"
    let sizeBytes: Int
    let sha256: String

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case feedID = "feed_id"
        case mimeType = "mime_type"
        case sizeBytes = "size_bytes"
        case sha256
    }
}

struct ModerateSightRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let feedID: UUID
    let uploadSessionID: UUID

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case feedID = "feed_id"
        case uploadSessionID = "upload_session_id"
    }
}

struct FeedResourceDTO: Decodable, Sendable, Equatable {
    let type: String
    let id: UUID
    let version: Int
    let kind: String
    let status: String
    let promiseStatus: String?

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case version
        case kind
        case status
        case promiseStatus = "promise_status"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "feed"
        id = try container.decode(UUID.self, forKey: .id)
        version = try container.decode(Int.self, forKey: .version)
        kind = try container.decode(String.self, forKey: .kind)
        status = try container.decode(String.self, forKey: .status)
        promiseStatus = try container.decodeIfPresent(String.self, forKey: .promiseStatus)
    }
}

struct MutationEventDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let type: String
    let occurredAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case occurredAt = "occurred_at"
    }
}

struct FeedMutationResultDTO: Decodable, Sendable, Equatable {
    let resource: FeedResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
    let events: [MutationEventDTO]
    let prop: String?

    enum CodingKeys: String, CodingKey {
        case resource
        case patch
        case quotas
        case events
        case prop
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resource = try container.decode(FeedResourceDTO.self, forKey: .resource)
        patch = try container.decode(SessionPatchDTO.self, forKey: .patch)
        quotas = try container.decodeIfPresent([QuotaEntryDTO].self, forKey: .quotas)
        events = try container.decodeIfPresent([MutationEventDTO].self, forKey: .events) ?? []
        prop = try container.decodeIfPresent(String.self, forKey: .prop)
    }
}

struct SightUploadURLResultDTO: Decodable, Sendable, Equatable {
    let uploadSessionID: UUID
    let method: String
    let url: String
    let headers: [String: String]
    let objectPath: String
    let expiresAt: Date
    let maxSizeBytes: Int

    enum CodingKeys: String, CodingKey {
        case uploadSessionID = "upload_session_id"
        case method
        case url
        case headers
        case objectPath = "object_path"
        case expiresAt = "expires_at"
        case maxSizeBytes = "max_size_bytes"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uploadSessionID = try container.decode(UUID.self, forKey: .uploadSessionID)
        method = try container.decodeIfPresent(String.self, forKey: .method) ?? "PUT"
        url = try container.decode(String.self, forKey: .url)
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers) ?? [:]
        objectPath = try container.decode(String.self, forKey: .objectPath)
        expiresAt = try container.decode(Date.self, forKey: .expiresAt)
        maxSizeBytes = try container.decode(Int.self, forKey: .maxSizeBytes)
    }
}

enum FeedEncoding {
    static func encodeBody<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }
}
