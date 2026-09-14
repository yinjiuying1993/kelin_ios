import XCTest
@testable import Kelin

final class PactAnswerQueueTests: XCTestCase {
    func testQueueReplaysInQuestionOrderAndKeepsClientID() async throws {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let store = PactAnswerQueueStore(localStore: LocalStore(modelContainer: container))
        let account = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
        let session = UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!
        let firstID = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!
        let secondID = UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!

        try await store.enqueue(
            PactAnswerQueueItem(
                clientID: secondID,
                sessionID: session,
                expectedSessionVersion: 2,
                questionID: "interview-v1-q2",
                text: "第二题",
                order: 1
            ),
            accountUserID: account
        )
        try await store.enqueue(
            PactAnswerQueueItem(
                clientID: firstID,
                sessionID: session,
                expectedSessionVersion: 1,
                questionID: "interview-v1-q1",
                text: "第一题",
                order: 0
            ),
            accountUserID: account
        )

        let first = try await store.next(accountUserID: account)
        XCTAssertEqual(first?.questionID, "interview-v1-q1")
        XCTAssertEqual(first?.clientID, firstID)
        try await store.remove(questionID: "interview-v1-q1", accountUserID: account)
        let second = try await store.next(accountUserID: account)
        XCTAssertEqual(second?.questionID, "interview-v1-q2")
        XCTAssertEqual(second?.clientID, secondID)
    }

    func testClientIDsSurviveReload() async throws {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let localStore = LocalStore(modelContainer: container)
        let ids = PactClientIDStore(localStore: localStore)
        let account = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
        let key = PactClientIDStore.answerKey(
            sessionID: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            questionID: "interview-v1-q3"
        )
        let first = try await ids.clientID(for: key, accountUserID: account)
        let again = try await PactClientIDStore(localStore: localStore).clientID(for: key, accountUserID: account)
        XCTAssertEqual(first, again)
    }
}
