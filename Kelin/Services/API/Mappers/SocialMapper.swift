import Foundation

enum SocialMapper {
    static func mapProfile(_ dto: PublicSpiritProfileDTO) throws -> PublicSpiritProfile {
        guard let stage = SpiritStage(rawValue: dto.stage),
              let status = SpiritStatus(rawValue: dto.status) else {
            throw AppError.decoding
        }
        return PublicSpiritProfile(
            id: dto.id,
            title: dto.title,
            stage: stage,
            publicMarks: dto.publicMarks,
            status: status
        )
    }

    static func mapNPC(_ dto: NpcProfileDTO) -> NpcProfile {
        NpcProfile(npcID: dto.npcID, title: dto.title, publicMarks: dto.publicMarks)
    }

    static func mapFriend(_ dto: FriendPublicDTO) throws -> Friend {
        Friend(
            friendID: dto.friendID,
            spirit: try mapProfile(dto.spirit),
            createdAt: dto.createdAt
        )
    }

    static func mapVisit(_ dto: VisitPublicDTO) throws -> Visit {
        guard let stage = SpiritStage(rawValue: dto.publicContext.stage) else {
            throw AppError.decoding
        }
        return Visit(
            id: dto.id,
            planID: dto.planID,
            destinationIndex: dto.destinationIndex,
            status: dto.status,
            host: try dto.host.map(mapProfile),
            npc: dto.npc.map(mapNPC),
            publicContext: VisitContext(
                title: dto.publicContext.title,
                stage: stage,
                weather: dto.publicContext.weather,
                publicMarks: dto.publicContext.publicMarks
            )
        )
    }

    static func mapPostcard(_ dto: PostcardPublicDTO) throws -> Postcard {
        Postcard(
            id: dto.id,
            visitID: dto.visitID,
            sender: try dto.sender.map(mapProfile),
            npc: dto.npc.map(mapNPC),
            text: dto.text,
            readAt: dto.readAt,
            createdAt: dto.createdAt,
            visit: try mapVisit(dto.visit)
        )
    }

    static func mapFriendPage(_ dto: FriendPageDTO) throws -> SocialPage<Friend> {
        SocialPage(
            items: try dto.items.map(mapFriend),
            nextCursor: dto.nextCursor,
            hasMore: dto.hasMore,
            snapshotAt: dto.snapshotAt
        )
    }

    static func mapPostcardPage(_ dto: PostcardPageDTO) throws -> SocialPage<Postcard> {
        SocialPage(
            items: try dto.items.map(mapPostcard),
            nextCursor: dto.nextCursor,
            hasMore: dto.hasMore,
            snapshotAt: dto.snapshotAt
        )
    }

    static func mapSocialPatch(_ dto: SocialPatchDTO) throws -> SocialPatchSnapshot {
        SocialPatchSnapshot(
            friendsUpsert: try dto.friendsUpsert.map(mapFriend),
            friendsRemoved: dto.friendsRemoved
        )
    }

    static func mapAdd(_ dto: AddFriendResultDTO, serverTime: Date?) throws -> SocialMutation {
        try mapMutation(patch: dto.patch, quotas: dto.quotas, serverTime: serverTime)
    }

    static func mapRemove(_ dto: RemoveFriendResultDTO, serverTime: Date?) throws -> SocialMutation {
        try mapMutation(patch: dto.patch, quotas: dto.quotas, serverTime: serverTime)
    }

    static func mapRead(_ dto: PostcardReadResultDTO, serverTime: Date?) throws -> SocialMutation {
        try mapMutation(patch: dto.patch, quotas: dto.quotas, serverTime: serverTime)
    }

    private static func mapMutation(
        patch: SessionPatchDTO,
        quotas: [QuotaEntryDTO]?,
        serverTime: Date?
    ) throws -> SocialMutation {
        let mapped = try SessionPatchMapper.map(patch, serverTime: serverTime)
        return SocialMutation(patch: try SessionPatchMapper.attachingQuotas(mapped, from: quotas))
    }
}
