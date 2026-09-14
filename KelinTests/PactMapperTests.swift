import XCTest
@testable import Kelin

final class PactMapperTests: XCTestCase {
    func testCreateSessionAnswerSkipDecodeDocumentFields() throws {
        let created = try PactMapper.mapCreate(
            PactContractFixtures.decode(PactContractFixtures.createSuccess, as: PactCreateResultDTO.self),
            serverTime: Date(timeIntervalSince1970: 1)
        )
        XCTAssertEqual(created.pact?.status, "active")
        XCTAssertEqual(created.pact?.completedSessions, 0)
        XCTAssertEqual(created.pact?.completeness, 0)
        XCTAssertEqual(created.patch.pact?.id, created.pact?.id)
        XCTAssertNil(created.patch.spirit)

        let session = try PactMapper.mapSessionResult(
            PactContractFixtures.decode(PactContractFixtures.sessionSuccess, as: PactSessionResultDTO.self),
            serverTime: Date(timeIntervalSince1970: 1)
        )
        XCTAssertEqual(session.session?.questions.count, 3)
        XCTAssertEqual(session.session?.questions.map(\.id), ["interview-v1-q1", "interview-v1-q2", "interview-v1-q3"])
        XCTAssertEqual(session.session?.rowVersion, 1)

        let incremental = try PactMapper.mapAnswerResult(
            PactContractFixtures.decode(PactContractFixtures.answerIncremental, as: PactAnswerResultDTO.self),
            serverTime: Date(timeIntervalSince1970: 1)
        )
        XCTAssertFalse(incremental.answer?.finalized ?? true)
        XCTAssertNil(incremental.answer?.score)
        XCTAssertEqual(incremental.pact?.completedSessions, 0)

        let finalized = try PactMapper.mapAnswerResult(
            PactContractFixtures.decode(PactContractFixtures.answerFinalized, as: PactAnswerResultDTO.self),
            serverTime: Date(timeIntervalSince1970: 1)
        )
        XCTAssertEqual(finalized.answer?.finalized, true)
        XCTAssertEqual(finalized.answer?.score, 82)
        XCTAssertEqual(finalized.answer?.pactStatus, "active")
        XCTAssertEqual(finalized.pact?.completedSessions, 1)
        XCTAssertEqual(finalized.pact?.completeness, 72)

        let skipped = try PactMapper.mapSkip(
            PactContractFixtures.decode(PactContractFixtures.skipSuccess, as: PactSkipResultDTO.self),
            serverTime: Date(timeIntervalSince1970: 1)
        )
        XCTAssertEqual(skipped.session?.status, "skipped")
        XCTAssertEqual(skipped.pact?.skippedSessions, 1)
        XCTAssertEqual(skipped.pact?.completedSessions, 0)
        XCTAssertEqual(skipped.pact?.completeness, 50)
    }

    func testQuestionPromptFieldIsRejected() {
        let json = """
        { "question_id": "interview-v1-q1", "text": "题面", "prompt": "旧字段" }
        """
        XCTAssertThrowsError(
            try APIDecoding.makeJSONDecoder().decode(PactQuestionDTO.self, from: Data(json.utf8))
        )
    }

    func testCreateBodyOmitsSettlementFields() throws {
        let data = try PactCacheRules.encodeCreateBody(
            theme: "interview",
            title: "面试题",
            clientID: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            notesMemoryID: nil
        )
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["client_id", "theme", "title"])
        for key in PactCacheRules.forbiddenRequestKeys() {
            XCTAssertNil(object[key])
        }
    }

    func testClientHasNoCompleteEndpointHelper() {
        XCTAssertTrue(
            P15PactContractManifest.forbiddenCompletePathFragments.allSatisfy { $0.contains("complete") }
        )
        XCTAssertFalse(P15PactContractManifest.allowsIndependentComplete)
    }
}
