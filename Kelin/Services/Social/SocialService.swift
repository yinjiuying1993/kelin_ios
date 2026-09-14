import Foundation

protocol SocialServiceProtocol: Sendable {
    func listFriends(cursor: String?, limit: Int) async throws -> SocialPage<Friend>
    func addFriend(inviteCode: String, clientID: UUID) async throws -> SocialMutation
    func removeFriend(friendID: UUID, clientID: UUID) async throws -> SocialMutation
    func listPostcards(unreadOnly: Bool, cursor: String?, limit: Int) async throws -> SocialPage<Postcard>
    func markRead(postcardID: UUID, clientID: UUID) async throws -> SocialMutation
}

actor APISocialService: SocialServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) {
        self.client = client
    }

    func listFriends(cursor: String?, limit: Int) async throws -> SocialPage<Friend> {
        let dto = try await client.send(
            .friends(cursor: cursor, limit: limit),
            responseType: FriendPageDTO.self
        )
        return try SocialMapper.mapFriendPage(dto)
    }

    func addFriend(inviteCode: String, clientID: UUID) async throws -> SocialMutation {
        let result = try await client.sendWithMetadata(
            .post(
                "/friends",
                body: APIDecoding.encodeBody(
                    AddFriendRequestDTO(clientID: clientID, inviteCode: inviteCode)
                )
            ),
            responseType: AddFriendResultDTO.self
        )
        return try SocialMapper.mapAdd(result.payload, serverTime: result.serverTime)
    }

    func removeFriend(friendID: UUID, clientID: UUID) async throws -> SocialMutation {
        let result = try await client.sendWithMetadata(
            .delete(
                "/friends/\(friendID.uuidString.lowercased())",
                body: APIDecoding.encodeBody(RemoveFriendRequestDTO(clientID: clientID))
            ),
            responseType: RemoveFriendResultDTO.self
        )
        return try SocialMapper.mapRemove(result.payload, serverTime: result.serverTime)
    }

    func listPostcards(unreadOnly: Bool, cursor: String?, limit: Int) async throws -> SocialPage<Postcard> {
        let dto = try await client.send(
            .postcards(unreadOnly: unreadOnly, cursor: cursor, limit: limit),
            responseType: PostcardPageDTO.self
        )
        return try SocialMapper.mapPostcardPage(dto)
    }

    func markRead(postcardID: UUID, clientID: UUID) async throws -> SocialMutation {
        let result = try await client.sendWithMetadata(
            .patch(
                "/postcards/\(postcardID.uuidString.lowercased())/read",
                body: APIDecoding.encodeBody(PostcardReadRequestDTO(clientID: clientID))
            ),
            responseType: PostcardReadResultDTO.self
        )
        return try SocialMapper.mapRead(result.payload, serverTime: result.serverTime)
    }
}

actor MockSocialService: SocialServiceProtocol {
    func listFriends(cursor: String?, limit: Int) async throws -> SocialPage<Friend> {
        SocialPage(items: [], nextCursor: nil, hasMore: false, snapshotAt: Date())
    }

    func addFriend(inviteCode: String, clientID: UUID) async throws -> SocialMutation {
        throw AppError.notFound
    }

    func removeFriend(friendID: UUID, clientID: UUID) async throws -> SocialMutation {
        throw AppError.notFound
    }

    func listPostcards(unreadOnly: Bool, cursor: String?, limit: Int) async throws -> SocialPage<Postcard> {
        SocialPage(items: [], nextCursor: nil, hasMore: false, snapshotAt: Date())
    }

    func markRead(postcardID: UUID, clientID: UUID) async throws -> SocialMutation {
        throw AppError.notFound
    }
}
