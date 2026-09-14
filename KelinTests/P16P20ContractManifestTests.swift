import XCTest
@testable import Kelin

final class P16P20ContractManifestTests: XCTestCase {
    func testLiveSHADiffersFromDocumentAndLocksPresentRoutes() {
        XCTAssertEqual(P16P20ContractManifest.liveOpenAPISHA256.count, 64)
        XCTAssertEqual(
            P16P20ContractManifest.liveOpenAPISHA256,
            "614c0fd78437ce625aa5f184088736b27388369aba40835bf8326b92cc18fb70"
        )
        XCTAssertEqual(
            P16P20ContractManifest.documentReviewedSHA256,
            "fed40c13c30d2203f20ed83c7ad208042c13f35e330d3491e407f22be0593230"
        )
        XCTAssertNotEqual(
            P16P20ContractManifest.liveOpenAPISHA256,
            P16P20ContractManifest.documentReviewedSHA256
        )
        XCTAssertTrue(P16P20ContractManifest.liveHasFriendsRoutes)
        XCTAssertTrue(P16P20ContractManifest.liveHasPostcardRoutes)
        XCTAssertTrue(P16P20ContractManifest.liveHasDeviceRoute)
        XCTAssertTrue(P16P20ContractManifest.liveHasReportRoutes)
        XCTAssertTrue(P16P20ContractManifest.liveHasSpiritPatch)
        XCTAssertTrue(P16P20ContractManifest.liveHasAccountDelete)
        XCTAssertFalse(P16P20ContractManifest.liveHasRecallRoute)
        XCTAssertFalse(P16P20ContractManifest.liveHasDebugRoutes)
        XCTAssertFalse(P16P20ContractManifest.liveHasVisitCreate)
        XCTAssertFalse(P16P20ContractManifest.liveHasIdentityLinkREST)
        XCTAssertEqual(P16P20ContractManifest.accountDeleteConfirm, "DELETE_MY_ACCOUNT")
        XCTAssertEqual(
            P16P20ContractManifest.publicSpiritProfileFields,
            ["id", "title", "stage", "public_marks", "status"]
        )
    }
}

final class SocialMapperTests: XCTestCase {
    func testPublicProfileRejectsPrivateFields() throws {
        let json = """
        {"id":"00000000-0000-4000-8000-000000000001","title":"雾里的那只","stage":"formed","public_marks":[],"status":"home","user_id":"x"}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try APIDecoding.makeJSONDecoder().decode(PublicSpiritProfileDTO.self, from: json))
    }

    func testPostcardRequiresExactlyOneSender() throws {
        let json = """
        {
          "id":"00000000-0000-4000-8000-000000000011",
          "visit_id":"00000000-0000-4000-8000-000000000012",
          "text":"门外看了一会儿。",
          "created_at":"2026-09-14T02:14:00Z",
          "visit":{
            "id":"00000000-0000-4000-8000-000000000013",
            "plan_id":"00000000-0000-4000-8000-000000000014",
            "destination_index":1,
            "status":"settled",
            "npc":{"npc_id":"fog","title":"雾里的那只"},
            "public_context":{"title":"雾里的那只","stage":"formed","weather":"阴"}
          }
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try APIDecoding.makeJSONDecoder().decode(PostcardPublicDTO.self, from: json))
    }
}

final class DeviceMapperTests: XCTestCase {
    func testDeviceResponseRejectsToken() throws {
        let json = """
        {"device_id":"00000000-0000-4000-8000-000000000021","enabled":true,"updated_at":"2026-09-14T03:00:00Z","apns_token":"secret-token-value"}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try APIDecoding.makeJSONDecoder().decode(DeviceRegistrationDTO.self, from: json))
    }
}

final class SettingsConflictRetryTests: XCTestCase {
    @MainActor
    func testConflictRefreshesBootstrapThenRetriesSamePayload() async throws {
        let service = RecordingSettingsService()
        await service.enqueue(.failure(.conflict))
        await service.enqueue(.success(Self.patch(version: 4)))

        let model = SettingsViewModel(
            spiritName: "雾生",
            spiritID: SettingsDraftFixtures.sampleSpiritID,
            inviteCode: "ABCD2345",
            preferences: SettingsDraftFixtures.defaultPreferences,
            friendCount: 0,
            isOffline: false,
            usesRemoteSettingsAPI: true,
            snapshotVersion: 2,
            settingsService: service,
            onRefreshSnapshot: { 4 }
        )

        model.setTTSOn(true)
        try await Task.sleep(for: .milliseconds(200))

        let versions = await service.expectedVersions
        XCTAssertEqual(versions, [2, 4])
        XCTAssertTrue(model.ttsOn)
        XCTAssertNil(model.bannerMessage)
    }

    private static func patch(version: Int) -> SessionPatch {
        SessionPatch(
            snapshotVersion: version,
            spirit: nil,
            preferences: nil,
            room: nil,
            onboarding: nil,
            serverTime: Date()
        )
    }
}

final class SocialPagingTests: XCTestCase {
    @MainActor
    func testRefreshLoadsAllFriendPages() async {
        let service = PagingSocialService()
        let model = SocialViewModel(
            inviteCode: "ABCD2345",
            isOffline: false,
            visitEnabled: true,
            usesRemoteSocialAPI: true,
            socialService: service
        )

        await model.refreshRemote()

        XCTAssertEqual(model.visiblePeers.map(\.title), ["灯下", "阴天"])
        XCTAssertEqual(model.phase, .friendsEmpty)
        XCTAssertNil(model.bannerMessage)
    }
}

actor RecordingSettingsService: SettingsServiceProtocol {
    private(set) var expectedVersions: [Int] = []
    private var results: [Result<SessionPatch, AppError>] = []

    func enqueue(_ result: Result<SessionPatch, AppError>) {
        results.append(result)
    }

    func patchSpirit(
        expectedVersion: Int,
        name: String?,
        preferences: PreferencesPatchDTO?,
        clientID: UUID
    ) async throws -> SessionPatch {
        expectedVersions.append(expectedVersion)
        guard !results.isEmpty else {
            throw AppError.unknown(requestID: "empty")
        }
        return try results.removeFirst().get()
    }

    func deleteAccount(clientID: UUID) async throws -> AccountDeletion {
        throw AppError.networkUnavailable
    }
}

actor PagingSocialService: SocialServiceProtocol {
    func listFriends(cursor: String?, limit: Int) async throws -> SocialPage<Friend> {
        if cursor == nil {
            return SocialPage(
                items: [Self.friend(id: 1, title: "灯下")],
                nextCursor: "page-2",
                hasMore: true,
                snapshotAt: Date()
            )
        }
        XCTAssertEqual(cursor, "page-2")
        return SocialPage(
            items: [Self.friend(id: 2, title: "阴天")],
            nextCursor: nil,
            hasMore: false,
            snapshotAt: Date()
        )
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

    private static func friend(id: Int, title: String) -> Friend {
        let spiritID = UUID(uuidString: String(format: "00000000-0000-4000-8000-0000000000%02d", id))!
        let friendID = UUID(uuidString: String(format: "00000000-0000-4000-8000-0000000001%02d", id))!
        return Friend(
            friendID: friendID,
            spirit: PublicSpiritProfile(
                id: spiritID,
                title: title,
                stage: .formed,
                publicMarks: [],
                status: .home
            ),
            createdAt: Date()
        )
    }
}
