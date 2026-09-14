import Foundation

struct PublicSpiritProfileDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let title: String
    let stage: String
    let publicMarks: [String]
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case stage
        case publicMarks = "public_marks"
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try MemoryDTOCoding.rejectUnknownKeys(
            in: container,
            allowed: Set(P16P20ContractManifest.publicSpiritProfileFields),
            debugDescription: "PublicSpiritProfile extra fields"
        )
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        stage = try container.decode(String.self, forKey: .stage)
        publicMarks = try container.decodeIfPresent([String].self, forKey: .publicMarks) ?? []
        status = try container.decode(String.self, forKey: .status)
    }
}

struct NpcProfileDTO: Decodable, Sendable, Equatable {
    let npcID: String
    let title: String
    let publicMarks: [String]

    enum CodingKeys: String, CodingKey {
        case npcID = "npc_id"
        case title
        case publicMarks = "public_marks"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        npcID = try container.decode(String.self, forKey: .npcID)
        title = try container.decode(String.self, forKey: .title)
        publicMarks = try container.decodeIfPresent([String].self, forKey: .publicMarks) ?? []
    }
}

struct FriendPublicDTO: Decodable, Sendable, Equatable {
    let friendID: UUID
    let spirit: PublicSpiritProfileDTO
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case friendID = "friend_id"
        case spirit
        case createdAt = "created_at"
    }
}

struct VisitContextDTO: Decodable, Sendable, Equatable {
    let title: String
    let stage: String
    let weather: String
    let publicMarks: [String]

    enum CodingKeys: String, CodingKey {
        case title
        case stage
        case weather
        case publicMarks = "public_marks"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        stage = try container.decode(String.self, forKey: .stage)
        weather = try container.decode(String.self, forKey: .weather)
        publicMarks = try container.decodeIfPresent([String].self, forKey: .publicMarks) ?? []
    }
}

struct VisitPublicDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let planID: UUID
    let destinationIndex: Int
    let status: String
    let host: PublicSpiritProfileDTO?
    let npc: NpcProfileDTO?
    let publicContext: VisitContextDTO

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case planID = "plan_id"
        case destinationIndex = "destination_index"
        case status
        case host
        case npc
        case publicContext = "public_context"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        planID = try container.decode(UUID.self, forKey: .planID)
        destinationIndex = try container.decode(Int.self, forKey: .destinationIndex)
        status = try container.decode(String.self, forKey: .status)
        host = try container.decodeIfPresent(PublicSpiritProfileDTO.self, forKey: .host)
        npc = try container.decodeIfPresent(NpcProfileDTO.self, forKey: .npc)
        publicContext = try container.decode(VisitContextDTO.self, forKey: .publicContext)
        if (host == nil) == (npc == nil) {
            throw DecodingError.dataCorruptedError(
                forKey: .host,
                in: container,
                debugDescription: "VisitPublic must have exactly one of host or npc"
            )
        }
    }
}

struct PostcardPublicDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let visitID: UUID
    let sender: PublicSpiritProfileDTO?
    let npc: NpcProfileDTO?
    let text: String
    let readAt: Date?
    let createdAt: Date
    let visit: VisitPublicDTO

    enum CodingKeys: String, CodingKey {
        case id
        case visitID = "visit_id"
        case sender
        case npc
        case text
        case readAt = "read_at"
        case createdAt = "created_at"
        case visit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        visitID = try container.decode(UUID.self, forKey: .visitID)
        sender = try container.decodeIfPresent(PublicSpiritProfileDTO.self, forKey: .sender)
        npc = try container.decodeIfPresent(NpcProfileDTO.self, forKey: .npc)
        text = try container.decode(String.self, forKey: .text)
        readAt = try container.decodeIfPresent(Date.self, forKey: .readAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        visit = try container.decode(VisitPublicDTO.self, forKey: .visit)
        if (sender == nil) == (npc == nil) {
            throw DecodingError.dataCorruptedError(
                forKey: .sender,
                in: container,
                debugDescription: "PostcardPublic must have exactly one of sender or npc"
            )
        }
    }
}

struct FriendPageDTO: Decodable, Sendable, Equatable {
    let items: [FriendPublicDTO]
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

struct PostcardPageDTO: Decodable, Sendable, Equatable {
    let items: [PostcardPublicDTO]
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

struct SocialPatchDTO: Decodable, Sendable, Equatable {
    let friendsUpsert: [FriendPublicDTO]
    let friendsRemoved: [UUID]

    enum CodingKeys: String, CodingKey {
        case friendsUpsert = "friends_upsert"
        case friendsRemoved = "friends_removed"
        case visitPlan = "visit_plan"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        friendsUpsert = try container.decodeIfPresent([FriendPublicDTO].self, forKey: .friendsUpsert) ?? []
        friendsRemoved = try container.decodeIfPresent([UUID].self, forKey: .friendsRemoved) ?? []
        _ = try container.decodeIfPresent(VisitPlanIgnoredDTO.self, forKey: .visitPlan)
    }
}

private struct VisitPlanIgnoredDTO: Decodable, Sendable, Equatable {}

struct AddFriendRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let inviteCode: String

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case inviteCode = "invite_code"
    }
}

struct RemoveFriendRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
    }
}

struct PostcardReadRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
    }
}

struct AddFriendResultDTO: Decodable, Sendable, Equatable {
    let resource: FriendPublicDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
}

struct RemoveFriendResultDTO: Decodable, Sendable, Equatable {
    let resource: MutationResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
}

struct PostcardReadResultDTO: Decodable, Sendable, Equatable {
    let resource: PostcardReadResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
}

struct PostcardReadResourceDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let readAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case readAt = "read_at"
    }
}
