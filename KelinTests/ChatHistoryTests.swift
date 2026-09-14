import SwiftData
import XCTest
@testable import Kelin

final class ChatHistoryRulesTests: XCTestCase {
    func testStableSortUsesCreatedAtThenClientID() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let first = MessagesDraftFixtures.sampleMessage(index: 1, createdAt: base)
        let second = MessagesDraftFixtures.sampleMessage(index: 2, createdAt: base.addingTimeInterval(1))
        let tieBreakA = ChatMessage(
            id: UUID(uuidString: "30000000-0000-4000-8000-000000000001")!,
            clientID: UUID(uuidString: "40000000-0000-4000-8000-000000000001")!,
            role: .user,
            content: "a",
            source: .text,
            status: .accepted,
            createdAt: base
        )
        let tieBreakB = ChatMessage(
            id: UUID(uuidString: "30000000-0000-4000-8000-000000000002")!,
            clientID: UUID(uuidString: "40000000-0000-4000-8000-000000000002")!,
            role: .user,
            content: "b",
            source: .text,
            status: .accepted,
            createdAt: base
        )

        let sorted = ChatHistoryRules.stableSort([second, tieBreakB, first, tieBreakA])

        XCTAssertEqual(sorted.map(\.id), [first.id, tieBreakA.id, tieBreakB.id, second.id])
    }

    func testMergeRemotePageDoesNotDuplicateExistingIDs() {
        let shared = MessagesDraftFixtures.sampleMessage(index: 10)
        let cached = [
            MessagesDraftFixtures.sampleMessage(index: 1),
            shared,
            MessagesDraftFixtures.sampleMessage(index: 2)
        ]
        let remotePage = MessagesPage(
            items: [
                shared,
                MessagesDraftFixtures.sampleMessage(index: 3)
            ],
            nextCursor: nil,
            hasMore: false,
            snapshotAt: MessagesDraftFixtures.snapshotAt
        )

        let merged = ChatHistoryRules.merge(existing: cached, remote: remotePage.items)

        XCTAssertEqual(Set(merged.map(\.id)).count, merged.count)
        XCTAssertEqual(merged.count, 4)
        XCTAssertTrue(merged.contains(where: { $0.id == shared.id }))
    }

    func testMergePrefersSettledRemoteOverLocalOutbound() {
        let messageID = UUID(uuidString: "10000000-0000-4000-8000-000000000099")!
        let clientID = UUID(uuidString: "20000000-0000-4000-8000-000000000099")!
        let createdAt = Date(timeIntervalSince1970: 1_700_000_100)

        let local = ChatMessage(
            id: messageID,
            clientID: clientID,
            role: .user,
            content: "queued draft",
            source: .text,
            status: .queued,
            createdAt: createdAt
        )
        let remote = ChatMessage(
            id: messageID,
            clientID: clientID,
            role: .user,
            content: "accepted on server",
            source: .text,
            status: .accepted,
            createdAt: createdAt
        )

        let merged = ChatHistoryRules.merge(existing: [local], remote: [remote])

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].status, .accepted)
        XCTAssertEqual(merged[0].content, "accepted on server")
    }

    func testMergeMatchesUserMessagesByClientIDWhenServerIDDiffers() {
        let localID = UUID(uuidString: "10000000-0000-4000-8000-000000000088")!
        let serverID = UUID(uuidString: "10000000-0000-4000-8000-000000000089")!
        let clientID = UUID(uuidString: "20000000-0000-4000-8000-000000000088")!
        let createdAt = Date(timeIntervalSince1970: 1_700_000_200)

        let local = ChatMessage(
            id: localID,
            clientID: clientID,
            role: .user,
            content: "queued draft",
            source: .text,
            status: .queued,
            createdAt: createdAt
        )
        let remote = ChatMessage(
            id: serverID,
            clientID: clientID,
            role: .user,
            content: "accepted on server",
            source: .text,
            status: .accepted,
            createdAt: createdAt
        )

        let merged = ChatHistoryRules.merge(existing: [local], remote: [remote])

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].id, serverID)
        XCTAssertEqual(merged[0].status, .accepted)
    }

    func testPresentableMessagesCollapsesQueuedDuplicateWhenServerIDDiffers() {
        let localID = UUID(uuidString: "10000000-0000-4000-8000-000000000071")!
        let serverID = UUID(uuidString: "10000000-0000-4000-8000-000000000072")!
        let clientID = UUID(uuidString: "20000000-0000-4000-8000-000000000071")!
        let createdAt = Date(timeIntervalSince1970: 1_700_000_300)

        let queued = ChatMessage(
            id: localID,
            clientID: clientID,
            role: .user,
            content: "同一句",
            source: .text,
            status: .queued,
            createdAt: createdAt
        )
        let accepted = ChatMessage(
            id: serverID,
            clientID: clientID,
            role: .user,
            content: "同一句",
            source: .text,
            status: .accepted,
            createdAt: createdAt
        )

        let collapsedAcceptedFirst = ChatHistoryRules.presentableMessages(from: [accepted, queued])
        let collapsedQueuedFirst = ChatHistoryRules.presentableMessages(from: [queued, accepted])

        XCTAssertEqual(collapsedAcceptedFirst.count, 1)
        XCTAssertEqual(collapsedAcceptedFirst[0].id, serverID)
        XCTAssertEqual(collapsedAcceptedFirst[0].status, .accepted)
        XCTAssertEqual(collapsedQueuedFirst, collapsedAcceptedFirst)
    }

    func testMessagesMapperDecodesFixtureEnvelope() throws {
        let data = Data(MessagesDraftFixtures.firstPageEnvelope.utf8)
        let envelope = try APIDecoding.makeJSONDecoder().decode(APIEnvelope<MessagesPageDTO>.self, from: data)
        let page = try MessagesMapper.map(envelope.data!)

        XCTAssertEqual(page.items.count, 2)
        XCTAssertTrue(page.hasMore)
        XCTAssertEqual(page.nextCursor, "cursor-page-1")
        XCTAssertEqual(page.items.map(\.role), [.spirit, .user])
    }
}

final class ChatHistoryCacheTests: XCTestCase {
    private var container: ModelContainer!
    private var store: LocalStore!
    private var cache: ChatHistoryCache!

    private let accountA = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
    private let accountB = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!

    override func setUpWithError() throws {
        container = try KelinModelContainerFactory.makeInMemoryContainer()
        store = LocalStore(modelContainer: container)
        cache = ChatHistoryCache(localStore: store)
    }

    override func tearDownWithError() throws {
        cache = nil
        store = nil
        container = nil
    }

    func testLoadCachedMessagesSkipsLegacyPayloadAndKeepsValidMessages() async throws {
        let valid = MessagesDraftFixtures.sampleMessage(index: 1)
        try await store.upsertMessage(
            CachedMessageRecord(
                id: valid.id,
                accountUserID: accountA,
                clientID: valid.clientID,
                payloadData: try MessageCodec.encode(valid),
                sendState: .sent,
                createdAt: valid.createdAt
            )
        )
        try await store.upsertMessage(
            CachedMessageRecord(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000FF")!,
                accountUserID: accountA,
                clientID: UUID(),
                payloadData: Data("legacy-raw-payload".utf8),
                sendState: .sent,
                createdAt: valid.createdAt.addingTimeInterval(-10)
            )
        )

        let loaded = try await cache.loadCachedMessages(accountUserID: accountA)

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].id, valid.id)
    }

    func testPersistAndMergePaginatedHistoryWithoutDuplicates() async throws {
        let mockService = MockMessagesService(configuration: .defaultPages(pageSize: 30, totalCount: 75))
        var merged: [ChatMessage] = []

        var cursor: String?
        repeat {
            let page = try await mockService.fetchMessages(cursor: cursor, limit: 30)
            merged = cache.mergeRemotePage(into: merged, page: page)
            cursor = page.nextCursor
        } while cursor != nil

        XCTAssertEqual(merged.count, 75)
        XCTAssertEqual(Set(merged.map(\.id)).count, 75)
        XCTAssertTrue(ChatHistoryRules.isOrderedBefore(merged[0], merged[1]))

        try await cache.applyMergedMessages(merged, accountUserID: accountA)

        let reloaded = try await cache.loadCachedMessages(accountUserID: accountA)
        XCTAssertEqual(reloaded.count, LocalStoreLimits.maxSentMessages)
        XCTAssertEqual(reloaded.map(\.id), ChatHistoryRules.presentableMessages(from: merged).suffix(LocalStoreLimits.maxSentMessages).map(\.id))
    }

    func testAccountIsolationForCachedMessages() async throws {
        let messageA = MessagesDraftFixtures.sampleMessage(index: 11)
        let messageB = MessagesDraftFixtures.sampleMessage(index: 12)

        try await cache.persistMessages([messageA], accountUserID: accountA)
        try await cache.persistMessages([messageB], accountUserID: accountB)

        let loadedA = try await cache.loadCachedMessages(accountUserID: accountA)
        let loadedB = try await cache.loadCachedMessages(accountUserID: accountB)

        XCTAssertEqual(loadedA.map(\.id), [messageA.id])
        XCTAssertEqual(loadedB.map(\.id), [messageB.id])
    }

    func testPersistKeepsQueuedMessagesWhenSentHistoryExceedsLimit() async throws {
        let queued = ChatMessage(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!,
            clientID: UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")!,
            role: .user,
            content: "still sending",
            source: .text,
            status: .queued,
            createdAt: Date(timeIntervalSince1970: 1_700_000_999)
        )
        var sentMessages: [ChatMessage] = []
        for index in 0..<55 {
            sentMessages.append(
                MessagesDraftFixtures.sampleMessage(
                    index: index + 1,
                    status: .accepted,
                    createdAt: Date(timeIntervalSince1970: 1_700_000_000 + TimeInterval(index))
                )
            )
        }

        try await cache.persistMessages(sentMessages + [queued], accountUserID: accountA)

        let records = try await store.fetchMessages(accountUserID: accountA)
        let queuedRecords = records.filter { $0.sendState == .queued }
        let sentRecords = records.filter { $0.sendState == .sent }

        XCTAssertEqual(queuedRecords.count, 1)
        XCTAssertEqual(queuedRecords.first?.id, queued.id)
        XCTAssertEqual(sentRecords.count, LocalStoreLimits.maxSentMessages)
    }
}
