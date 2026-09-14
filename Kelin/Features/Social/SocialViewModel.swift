import Foundation

@MainActor
@Observable
final class SocialViewModel {
    private(set) var phase: SocialScreenPhase
    private(set) var peers: [SocialPeerFixture]
    private(set) var postcard: SocialPostcardFixture?
    private(set) var visitEnabled: Bool
    private(set) var copiedInviteCode = false
    private(set) var bannerMessage: String?
    var showsAddFriend = false
    var draftInviteCode = ""
    var pendingUnfriend: SocialPeerFixture?

    let inviteCode: String
    let isOffline: Bool
    let usesRemoteSocialAPI: Bool
    private let socialService: (any SocialServiceProtocol)?
    private let settingsService: (any SettingsServiceProtocol)?
    private let localStore: LocalStore?
    private let clientIDs: P16P20ClientIDStore?
    private let accountUserID: UUID?
    private let onPatch: ((SessionPatch) -> Void)?
    private let onFriendCount: ((Int) -> Void)?
    private var snapshotVersion: Int
    private var remotePostcardID: UUID?
    private var unreadCursor: String?
    private var unreadOnlyFilter = true

    var visiblePeers: [SocialPeerFixture] {
        switch phase {
        case .noFriends:
            SocialDraftFixtures.npcPeers
        case .friendsEmpty, .unreadPostcard:
            peers
        }
    }

    var friendsSectionNote: String? {
        phase == .noFriends ? SocialPresentationRules.noFriendsCopy() : nil
    }

    var visitsSectionTitle: String {
        phase == .unreadPostcard
            ? SocialDraftFixtures.lastNightTitle
            : SocialDraftFixtures.latestVisitsTitle
    }

    var visitsSectionMeta: String {
        if phase == .unreadPostcard {
            return postcard?.timeLabel ?? SocialDraftFixtures.emptyVisitsLabel
        }
        return SocialDraftFixtures.emptyVisitsLabel
    }

    var visitHint: String {
        visitEnabled
            ? SocialDraftFixtures.allowVisitsSubtitle
            : SocialPresentationRules.visitOffCopy()
    }

    var showsUnfriendConfirm: Bool {
        get { pendingUnfriend != nil }
        set {
            if !newValue {
                pendingUnfriend = nil
            }
        }
    }

    init(
        inviteCode: String,
        isOffline: Bool,
        visitEnabled: Bool,
        usesRemoteSocialAPI: Bool = false,
        phase: SocialScreenPhase = .noFriends,
        socialService: (any SocialServiceProtocol)? = nil,
        settingsService: (any SettingsServiceProtocol)? = nil,
        localStore: LocalStore? = nil,
        clientIDs: P16P20ClientIDStore? = nil,
        accountUserID: UUID? = nil,
        snapshotVersion: Int = 0,
        onPatch: ((SessionPatch) -> Void)? = nil,
        onFriendCount: ((Int) -> Void)? = nil
    ) {
        let remote = usesRemoteSocialAPI && socialService != nil
        self.inviteCode = inviteCode.isEmpty && !remote
            ? SocialPresentationRules.sampleInviteCode
            : inviteCode
        self.isOffline = isOffline
        self.usesRemoteSocialAPI = remote
        self.socialService = socialService
        self.settingsService = settingsService
        self.localStore = localStore
        self.clientIDs = clientIDs
        self.accountUserID = accountUserID
        self.snapshotVersion = snapshotVersion
        self.onPatch = onPatch
        self.onFriendCount = onFriendCount
        self.visitEnabled = visitEnabled
        if remote {
            self.phase = .noFriends
            peers = []
            postcard = nil
        } else {
            self.phase = phase
            switch phase {
            case .noFriends:
                peers = SocialDraftFixtures.npcPeers
                postcard = nil
            case .friendsEmpty:
                peers = SocialDraftFixtures.friendPeers
                postcard = nil
            case .unreadPostcard:
                peers = SocialDraftFixtures.friendPeers
                postcard = SocialDraftFixtures.unreadPostcard
            }
        }
    }

    func copyInviteCode() {
        copiedInviteCode = true
        bannerMessage = String(localized: "邀请码已复制")
    }

    func setVisitEnabled(_ enabled: Bool) {
        let previous = visitEnabled
        visitEnabled = enabled
        guard usesRemoteSocialAPI, let settingsService else { return }
        Task {
            do {
                let clientID = try await stableClientID(for: P16P20ClientIDStore.settingsVisitKey)
                let patch = try await settingsService.patchSpirit(
                    expectedVersion: snapshotVersion,
                    name: nil,
                    preferences: PreferencesPatchDTO(visitOn: enabled),
                    clientID: clientID
                )
                snapshotVersion = patch.snapshotVersion
                onPatch?(patch)
                try? await forgetClientID(P16P20ClientIDStore.settingsVisitKey)
            } catch {
                visitEnabled = previous
                bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
            }
        }
    }

    func markPostcardRead() {
        guard var postcard else { return }
        let previous = postcard
        postcard.isUnread = false
        self.postcard = postcard
        guard usesRemoteSocialAPI, let socialService, let remotePostcardID else { return }
        Task {
            do {
                let clientID = try await stableClientID(for: P16P20ClientIDStore.postcardReadKey(remotePostcardID))
                let mutation = try await socialService.markRead(postcardID: remotePostcardID, clientID: clientID)
                onPatch?(mutation.patch)
                await cache(postcards: mutation.patch.postcardsUpsert)
            } catch {
                self.postcard = previous
                bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
            }
        }
    }

    func replyToPostcard() {
        bannerMessage = String(localized: "回应先留在这一页，不会替你选去谁家")
    }

    func submitFriendCode() {
        do {
            let code = try SocialPresentationRules.validateInviteCode(draftInviteCode, selfCode: inviteCode)
            guard usesRemoteSocialAPI, let socialService else {
                bannerMessage = String(localized: "社交接口尚未开通，邀请码先留在这一页")
                showsAddFriend = false
                draftInviteCode = ""
                return
            }
            Task {
                do {
                    let clientID = try await stableClientID(for: P16P20ClientIDStore.addFriendKey(code))
                    let mutation = try await socialService.addFriend(inviteCode: code, clientID: clientID)
                    onPatch?(mutation.patch)
                    showsAddFriend = false
                    draftInviteCode = ""
                    await refreshRemote()
                } catch {
                    bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
                }
            }
        } catch {
            bannerMessage = String(localized: "邀请码不对，或不能填自己的")
        }
    }

    func selectPeer(_ peer: SocialPeerFixture) {
        guard peer.kind == .friend else { return }
        pendingUnfriend = peer
    }

    func confirmUnfriend() {
        guard let pendingUnfriend else { return }
        peers.removeAll { $0.id == pendingUnfriend.id }
        self.pendingUnfriend = nil
        guard usesRemoteSocialAPI, let socialService, let friendID = UUID(uuidString: pendingUnfriend.id) else {
            return
        }
        Task {
            do {
                let clientID = try await stableClientID(for: P16P20ClientIDStore.removeFriendKey(friendID))
                let mutation = try await socialService.removeFriend(friendID: friendID, clientID: clientID)
                onPatch?(mutation.patch)
            } catch {
                bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
                await refreshRemote()
            }
        }
    }

    func refreshRemote() async {
        guard usesRemoteSocialAPI, let socialService else { return }
        unreadOnlyFilter = true
        unreadCursor = nil
        do {
            let friends = try await fetchAllFriends(using: socialService)
            let cards = try await fetchPostcards(using: socialService, unreadOnly: true)
            apply(friends: friends, postcards: cards)
            await cache(postcards: cards)
            onFriendCount?(friends.count)
        } catch {
            if isOffline || (error as? AppError) == .networkUnavailable {
                await applyCachedPostcards(friendsFallback: peers)
            }
            bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
        }
    }

    private func apply(friends: [Friend], postcards: [Postcard]) {
        if friends.isEmpty {
            phase = .noFriends
            peers = SocialDraftFixtures.npcPeers
        } else {
            peers = friends.map(Self.peer(from:))
            phase = postcards.contains(where: \.isUnread) ? .unreadPostcard : .friendsEmpty
        }
        if let first = postcards.first {
            postcard = Self.card(from: first)
            remotePostcardID = first.id
        } else {
            postcard = nil
            remotePostcardID = nil
        }
    }

    private static func peer(from friend: Friend) -> SocialPeerFixture {
        SocialPeerFixture(
            id: friend.friendID.uuidString,
            title: friend.spirit.title,
            subtitle: statusCopy(friend.spirit.status),
            kind: .friend,
            symbol: "sparkle",
            tint: .accent
        )
    }

    private static func statusCopy(_ status: SpiritStatus) -> String {
        switch status {
        case .home: String(localized: "在家")
        case .away: String(localized: "夜行")
        case .study: String(localized: "求知")
        case .lost: String(localized: "走失")
        }
    }

    private static func card(from postcard: Postcard) -> SocialPostcardFixture {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return SocialPostcardFixture(
            id: postcard.id,
            senderTitle: postcard.senderTitle,
            timeLabel: formatter.string(from: postcard.createdAt),
            body: postcard.text,
            isUnread: postcard.isUnread
        )
    }

    private func fetchAllFriends(using socialService: any SocialServiceProtocol) async throws -> [Friend] {
        var cursor: String?
        var items: [Friend] = []
        var retriedCursor = false
        while items.count < 500 {
            do {
                let page = try await socialService.listFriends(cursor: cursor, limit: 30)
                items.append(contentsOf: page.items)
                if page.hasMore, let next = page.nextCursor, !next.isEmpty {
                    cursor = next
                } else {
                    break
                }
            } catch let error as AppError where error == .invalidCursor && !retriedCursor {
                retriedCursor = true
                cursor = nil
                items = []
            }
        }
        return items
    }

    private func fetchPostcards(
        using socialService: any SocialServiceProtocol,
        unreadOnly: Bool
    ) async throws -> [Postcard] {
        if unreadOnly != unreadOnlyFilter {
            unreadCursor = nil
            unreadOnlyFilter = unreadOnly
        }
        var cursor: String? = unreadOnly ? unreadCursor : nil
        var items: [Postcard] = []
        var retriedCursor = false
        while items.count < 500 {
            do {
                let page = try await socialService.listPostcards(
                    unreadOnly: unreadOnly,
                    cursor: cursor,
                    limit: 30
                )
                items.append(contentsOf: page.items)
                if page.hasMore, let next = page.nextCursor, !next.isEmpty {
                    cursor = next
                    if unreadOnly {
                        unreadCursor = next
                    }
                } else {
                    unreadCursor = nil
                    break
                }
            } catch let error as AppError where error == .invalidCursor && !retriedCursor {
                retriedCursor = true
                cursor = nil
                unreadCursor = nil
                items = []
            }
        }
        return items
    }

    private func cache(postcards: [Postcard]) async {
        guard let localStore, let accountUserID else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        for postcard in postcards {
            guard let payload = try? encoder.encode(postcard) else { continue }
            try? await localStore.upsertPostcard(
                CachedPostcardRecord(
                    id: postcard.id,
                    accountUserID: accountUserID,
                    payloadData: payload,
                    isRead: !postcard.isUnread,
                    createdAt: postcard.createdAt
                )
            )
        }
    }

    private func applyCachedPostcards(friendsFallback: [SocialPeerFixture]) async {
        guard let localStore, let accountUserID else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = (try? await localStore.fetchPostcards(accountUserID: accountUserID)) ?? []
        let cards = records.compactMap { record -> Postcard? in
            try? decoder.decode(Postcard.self, from: record.payloadData)
        }
        if friendsFallback.contains(where: { $0.kind == .friend }) {
            if let first = cards.first(where: \.isUnread) ?? cards.first {
                postcard = Self.card(from: first)
                remotePostcardID = first.id
                phase = first.isUnread ? .unreadPostcard : .friendsEmpty
            }
        }
    }

    private func stableClientID(for key: String) async throws -> UUID {
        if let clientIDs, let accountUserID {
            return try await clientIDs.clientID(for: key, accountUserID: accountUserID)
        }
        return UUID()
    }

    private func forgetClientID(_ key: String) async throws {
        guard let clientIDs, let accountUserID else { return }
        try await clientIDs.forget(key: key, accountUserID: accountUserID)
    }

    func previewEmpty() {
        phase = .noFriends
        peers = SocialDraftFixtures.npcPeers
        postcard = nil
        visitEnabled = true
    }

    func previewFriendsEmpty() {
        phase = .friendsEmpty
        peers = SocialDraftFixtures.friendPeers
        postcard = nil
        visitEnabled = true
    }

    func previewUnread() {
        phase = .unreadPostcard
        peers = SocialDraftFixtures.friendPeers
        postcard = SocialDraftFixtures.unreadPostcard
        visitEnabled = true
    }

    func previewVisitOff() {
        visitEnabled = false
    }
}
