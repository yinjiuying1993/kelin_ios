import XCTest
@testable import Kelin

final class SocialPresentationTests: XCTestCase {
    func testCopyMatchesS09Specification() {
        XCTAssertEqual(SocialPresentationRules.screenTitle(), "足迹")
        XCTAssertEqual(SocialPresentationRules.inviteLabel(), "你的灵体邀请码")
        XCTAssertEqual(SocialPresentationRules.sampleInviteCode, "ABCD2345")
        XCTAssertEqual(SocialPresentationRules.emptyFootprintsTitle(), "门口还没有新的足迹")
        XCTAssertEqual(SocialPresentationRules.noFriendsCopy(), "它仍会遇到雾里的那只。")
        XCTAssertEqual(
            SocialPresentationRules.visitOffCopy(),
            "它仍可以去官方精灵那里，但不会进入朋友房间。"
        )
        XCTAssertEqual(SocialPresentationRules.unfriendTitle(), "不再让它们来往？")
        XCTAssertEqual(SocialPresentationRules.unfriendMessage(), "已有明信片仍会保留。")
        XCTAssertEqual(SocialPresentationRules.unfriendAction(), "解除")
        XCTAssertEqual(SocialDraftFixtures.unreadPostcard.senderTitle, "雾里的那只")
        XCTAssertEqual(SocialDraftFixtures.unreadPostcard.timeLabel, "02:14")
        XCTAssertEqual(
            SocialDraftFixtures.unreadPostcard.body,
            "“它们家太亮，我站在门外看了一会儿。”"
        )
        XCTAssertEqual(SocialDraftFixtures.npcPeers.count, 3)
        XCTAssertTrue(SocialDraftFixtures.npcPeers.allSatisfy { $0.kind == .npc })
        XCTAssertTrue(SocialDraftFixtures.friendPeers.allSatisfy { $0.kind == .friend })
    }

    func testInviteCodeNormalizesAndRejectsSelf() throws {
        XCTAssertEqual(SocialPresentationRules.normalizeInviteCode(" ab cd 2345 "), "ABCD2345")
        XCTAssertEqual(
            try SocialPresentationRules.validateInviteCode("efgh6789", selfCode: "ABCD2345"),
            "EFGH6789"
        )
        XCTAssertThrowsError(
            try SocialPresentationRules.validateInviteCode("ab cd 2345", selfCode: "ABCD2345")
        )
        XCTAssertThrowsError(
            try SocialPresentationRules.validateInviteCode("   ", selfCode: "ABCD2345")
        )
    }

    @MainActor
    func testDraftStatesStayLocalAndNeverEnableRemoteSocial() {
        let model = SocialViewModel(
            inviteCode: "ABCD2345",
            isOffline: false,
            visitEnabled: true
        )
        XCTAssertEqual(model.phase, .noFriends)
        XCTAssertNil(model.postcard)
        XCTAssertEqual(model.visiblePeers.count, 3)
        XCTAssertEqual(model.friendsSectionNote, "它仍会遇到雾里的那只。")
        XCTAssertFalse(model.usesRemoteSocialAPI)

        model.previewUnread()
        XCTAssertEqual(model.phase, .unreadPostcard)
        XCTAssertEqual(model.postcard?.isUnread, true)
        XCTAssertEqual(model.visiblePeers.map(\.kind), [.friend, .friend])
        XCTAssertNil(model.friendsSectionNote)

        model.markPostcardRead()
        XCTAssertEqual(model.postcard?.isUnread, false)
        XCTAssertNotNil(model.postcard)

        model.replyToPostcard()
        XCTAssertEqual(model.bannerMessage, "回应先留在这一页，不会替你选去谁家")
        XCTAssertFalse(model.usesRemoteSocialAPI)
    }

    @MainActor
    func testUnfriendRemovesFriendButKeepsPostcard() {
        let model = SocialViewModel(
            inviteCode: "ABCD2345",
            isOffline: false,
            visitEnabled: true,
            phase: .unreadPostcard
        )
        model.selectPeer(SocialDraftFixtures.npcPeers[0])
        XCTAssertNil(model.pendingUnfriend)

        model.selectPeer(SocialDraftFixtures.friendPeers[0])
        XCTAssertEqual(model.pendingUnfriend?.id, "friend.lamp")
        model.confirmUnfriend()
        XCTAssertEqual(model.visiblePeers.map(\.id), ["friend.overcast"])
        XCTAssertNotNil(model.postcard)
        XCTAssertEqual(model.postcard?.body, "“它们家太亮，我站在门外看了一会儿。”")
    }

    @MainActor
    func testVisitOffCopyAndSelfInviteRejectionStayLocal() {
        let model = SocialViewModel(
            inviteCode: "ABCD2345",
            isOffline: false,
            visitEnabled: true
        )
        model.setVisitEnabled(false)
        XCTAssertEqual(model.visitHint, "它仍可以去官方精灵那里，但不会进入朋友房间。")

        model.draftInviteCode = "abcd2345"
        model.submitFriendCode()
        XCTAssertEqual(model.bannerMessage, "邀请码不对，或不能填自己的")

        model.draftInviteCode = " kelin 99 "
        model.submitFriendCode()
        XCTAssertEqual(model.bannerMessage, "社交接口尚未开通，邀请码先留在这一页")
        XCTAssertFalse(model.usesRemoteSocialAPI)
    }
}
