import XCTest
@testable import Kelin

final class MemoryMapperTests: XCTestCase {
    func testListPageMapsActiveItemsAndTombstones() throws {
        let dto = try APIDecoding.makeJSONDecoder().decode(
            MemoryPageDTO.self,
            from: Data(MemoryDraftFixtures.listPageJSON.utf8)
        )
        let page = try MemoryMapper.mapPage(dto)

        XCTAssertEqual(page.items.count, 1)
        XCTAssertEqual(page.items[0].summary, "不要叫宝宝，要叫阿年")
        XCTAssertEqual(page.items[0].version, 1)
        XCTAssertEqual(page.tombstones.count, 1)
        XCTAssertEqual(page.tombstones[0].id, MemoryDraftFixtures.deletedID)
        XCTAssertFalse(page.hasMore)
        XCTAssertNil(page.nextCursor)
    }

    func testTombstoneWithSummaryFails() {
        XCTAssertThrowsError(
            try APIDecoding.makeJSONDecoder().decode(
                MemoryTombstoneDTO.self,
                from: Data(MemoryDraftFixtures.tombstoneWithSummaryJSON.utf8)
            )
        )
    }

    func testCorrectMutationMapsUpsert() throws {
        let dto = try APIDecoding.makeJSONDecoder().decode(
            MutationResultDTO.self,
            from: Data(MemoryDraftFixtures.correctPatchJSON.utf8)
        )
        let mutation = try MemoryMapper.mapMutation(dto, serverTime: nil)

        XCTAssertEqual(mutation.resourceType, "memory")
        XCTAssertEqual(mutation.resourceStatus, "active")
        XCTAssertEqual(mutation.patch.memoriesUpsert.first?.summary, "请叫我阿年")
        XCTAssertEqual(mutation.patch.memoriesUpsert.first?.version, 2)
        XCTAssertTrue(mutation.patch.memoryTombstones.isEmpty)
        XCTAssertFalse(mutation.patch.clearsAllMemories)
    }

    func testClearMutationSetsFlagEvenWhenTombstonesEmpty() throws {
        let dto = try APIDecoding.makeJSONDecoder().decode(
            MutationResultDTO.self,
            from: Data(MemoryDraftFixtures.clearPatchJSON.utf8)
        )
        let mutation = try MemoryMapper.mapMutation(dto, serverTime: nil)

        XCTAssertEqual(mutation.resourceType, "memory_clear")
        XCTAssertTrue(mutation.patch.clearsAllMemories)
        XCTAssertTrue(mutation.patch.memoryTombstones.isEmpty)
        XCTAssertTrue(mutation.patch.memoriesUpsert.isEmpty)
    }
}
