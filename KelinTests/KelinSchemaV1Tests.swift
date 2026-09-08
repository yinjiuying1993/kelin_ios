import SwiftData
import XCTest
@testable import Kelin

@MainActor
final class KelinSchemaV1Tests: XCTestCase {
    func testInMemoryContainerUsesVersionedSchemaBaseline() throws {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()

        XCTAssertEqual(KelinSchemaV1.versionIdentifier, Schema.Version(1, 0, 0))
        XCTAssertTrue(KelinMigrationPlan.stages.isEmpty)
        XCTAssertNotNil(container.mainContext)
    }

    func testAllV1ModelsCanBeSavedAndFetched() throws {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let context = container.mainContext
        let accountUserID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        context.insert(
            CachedBootstrap(
                accountUserID: accountUserID,
                payloadData: Data("bootstrap".utf8),
                snapshotVersion: 1,
                updatedAt: now
            )
        )
        context.insert(
            CachedMessage(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!,
                accountUserID: accountUserID,
                clientID: UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!,
                payloadData: Data("message".utf8),
                sendState: .queued,
                createdAt: now
            )
        )
        context.insert(
            CachedMemory(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")!,
                accountUserID: accountUserID,
                payloadData: Data("memory".utf8),
                isTombstone: false,
                updatedAt: now
            )
        )
        context.insert(
            CachedPostcard(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000E1")!,
                accountUserID: accountUserID,
                payloadData: Data("postcard".utf8),
                isRead: false,
                createdAt: now
            )
        )
        context.insert(
            CachedPact(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000F1")!,
                accountUserID: accountUserID,
                payloadData: Data("pact".utf8),
                updatedAt: now
            )
        )
        context.insert(
            Draft(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
                accountUserID: accountUserID,
                kind: .chat,
                payloadData: Data("draft".utf8),
                updatedAt: now
            )
        )
        context.insert(
            PendingOperation(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
                accountUserID: accountUserID,
                kind: .chat,
                clientID: UUID(uuidString: "00000000-0000-0000-0000-000000000031")!,
                payloadData: Data("pending".utf8),
                createdAt: now,
                attemptCount: 0,
                nextRetryAt: nil,
                lastErrorCode: nil,
                state: .pending
            )
        )

        try context.save()

        let bootstrapFetch = try context.fetch(FetchDescriptor<CachedBootstrap>())
        let messageFetch = try context.fetch(FetchDescriptor<CachedMessage>())
        let memoryFetch = try context.fetch(FetchDescriptor<CachedMemory>())
        let postcardFetch = try context.fetch(FetchDescriptor<CachedPostcard>())
        let pactFetch = try context.fetch(FetchDescriptor<CachedPact>())
        let draftFetch = try context.fetch(FetchDescriptor<Draft>())
        let pendingFetch = try context.fetch(FetchDescriptor<PendingOperation>())

        XCTAssertEqual(bootstrapFetch.count, 1)
        XCTAssertEqual(messageFetch.count, 1)
        XCTAssertEqual(memoryFetch.count, 1)
        XCTAssertEqual(postcardFetch.count, 1)
        XCTAssertEqual(pactFetch.count, 1)
        XCTAssertEqual(draftFetch.count, 1)
        XCTAssertEqual(pendingFetch.count, 1)

        XCTAssertEqual(bootstrapFetch.first?.accountUserID, accountUserID)
        XCTAssertEqual(messageFetch.first?.sendState, .queued)
        XCTAssertEqual(draftFetch.first?.kind, .chat)
        XCTAssertEqual(pendingFetch.first?.kind, .chat)
        XCTAssertEqual(pendingFetch.first?.state, .pending)
        XCTAssertEqual(pendingFetch.first?.clientID.uuidString, "00000000-0000-0000-0000-000000000031")
    }

    func testPendingOperationStoresRequiredFields() throws {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let context = container.mainContext
        let accountUserID = UUID()
        let clientID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_700_000_100)
        let nextRetryAt = Date(timeIntervalSince1970: 1_700_000_200)

        context.insert(
            PendingOperation(
                id: UUID(),
                accountUserID: accountUserID,
                kind: .memoryDelete,
                clientID: clientID,
                payloadData: Data("{}".utf8),
                createdAt: createdAt,
                attemptCount: 2,
                nextRetryAt: nextRetryAt,
                lastErrorCode: "NETWORK_UNAVAILABLE",
                state: .failed
            )
        )
        try context.save()

        let pending = try XCTUnwrap(try context.fetch(FetchDescriptor<PendingOperation>()).first)
        XCTAssertEqual(pending.kind, .memoryDelete)
        XCTAssertEqual(pending.state, .failed)
        XCTAssertEqual(pending.attemptCount, 2)
        XCTAssertEqual(pending.lastErrorCode, "NETWORK_UNAVAILABLE")
        XCTAssertEqual(pending.nextRetryAt, nextRetryAt)
        XCTAssertEqual(pending.clientID, clientID)
    }

    func testInMemoryContainerHasNoPersistentStoreURL() throws {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let configurations = container.configurations

        XCTAssertFalse(configurations.isEmpty)
        XCTAssertTrue(configurations.allSatisfy(\.isStoredInMemoryOnly))
    }
}
