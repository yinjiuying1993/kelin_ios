import Foundation

enum PactContractFixtures {
    static let createSuccess = """
    {
      "resource": {
        "id": "11111111-1111-4111-8111-111111111111",
        "theme": "interview",
        "title": "面试题",
        "status": "active",
        "question_bank_version": "interview-v1",
        "completed_sessions": 0,
        "skipped_sessions": 0,
        "completeness": 0,
        "scholar_mark": null
      },
      "patch": {
        "snapshot_version": 20,
        "spirit": null,
        "room": null,
        "pact": {
          "id": "11111111-1111-4111-8111-111111111111",
          "theme": "interview",
          "title": "面试题",
          "status": "active",
          "question_bank_version": "interview-v1",
          "completed_sessions": 0,
          "skipped_sessions": 0,
          "completeness": 0,
          "scholar_mark": null
        }
      },
      "quotas": [],
      "events": [
        {
          "id": "21111111-1111-4111-8111-111111111111",
          "type": "pact.created",
          "occurred_at": "2026-09-12T06:00:00Z"
        }
      ]
    }
    """

    static let sessionSuccess = """
    {
      "resource": {
        "id": "12111111-1111-4111-8111-111111111111",
        "pact_id": "11111111-1111-4111-8111-111111111111",
        "date": "2026-09-12",
        "explain": "今晚先把项目经历讲清楚。",
        "row_version": 1,
        "status": "ready",
        "day_index": 3,
        "answered_count": 0,
        "questions": [
          { "question_id": "interview-v1-q1", "text": "讲一个你做过的项目，最困难的决定是什么？" },
          { "question_id": "interview-v1-q2", "text": "如果重来一次，你会怎样量化那个结果？" },
          { "question_id": "interview-v1-q3", "text": "对方追问风险时，你准备先讲哪一句？" }
        ]
      },
      "patch": {
        "snapshot_version": 21,
        "spirit": null,
        "room": null,
        "pact": {
          "id": "11111111-1111-4111-8111-111111111111",
          "theme": "interview",
          "title": "面试题",
          "status": "active",
          "question_bank_version": "interview-v1",
          "completed_sessions": 0,
          "skipped_sessions": 0,
          "completeness": 0,
          "scholar_mark": null
        }
      },
      "quotas": [],
      "events": []
    }
    """

    static let answerIncremental = """
    {
      "resource": {
        "finalized": false,
        "score": null,
        "pact_status": null,
        "feedback": { "summary": "方向清楚，可以再具体一点。" },
        "mistakes": [],
        "answered_count": 1,
        "row_version": 2
      },
      "patch": {
        "snapshot_version": 22,
        "spirit": null,
        "room": null,
        "pact": {
          "id": "11111111-1111-4111-8111-111111111111",
          "theme": "interview",
          "title": "面试题",
          "status": "active",
          "question_bank_version": "interview-v1",
          "completed_sessions": 0,
          "skipped_sessions": 0,
          "completeness": 0,
          "scholar_mark": null
        }
      },
      "quotas": [],
      "events": [
        {
          "id": "22111111-1111-4111-8111-111111111111",
          "type": "pact.answered",
          "occurred_at": "2026-09-12T06:10:00Z"
        }
      ]
    }
    """

    static let answerFinalized = """
    {
      "resource": {
        "finalized": true,
        "score": 82,
        "pact_status": "active",
        "feedback": { "summary": "三题已齐，本场结束。" },
        "mistakes": [
          { "question_id": "interview-v1-q1", "summary": "结果没有量化" }
        ],
        "answered_count": 3,
        "row_version": 4
      },
      "patch": {
        "snapshot_version": 24,
        "spirit": null,
        "room": null,
        "pact": {
          "id": "11111111-1111-4111-8111-111111111111",
          "theme": "interview",
          "title": "面试题",
          "status": "active",
          "question_bank_version": "interview-v1",
          "completed_sessions": 1,
          "skipped_sessions": 0,
          "completeness": 72,
          "scholar_mark": null
        }
      },
      "quotas": [],
      "events": [
        {
          "id": "23111111-1111-4111-8111-111111111111",
          "type": "pact.answered",
          "occurred_at": "2026-09-12T06:20:00Z"
        }
      ]
    }
    """

    static let skipSuccess = """
    {
      "resource": {
        "id": "13111111-1111-4111-8111-111111111111",
        "pact_id": "11111111-1111-4111-8111-111111111111",
        "date": "2026-09-12",
        "status": "skipped",
        "row_version": 1,
        "questions": []
      },
      "patch": {
        "snapshot_version": 25,
        "spirit": null,
        "room": null,
        "pact": {
          "id": "11111111-1111-4111-8111-111111111111",
          "theme": "interview",
          "title": "面试题",
          "status": "active",
          "question_bank_version": "interview-v1",
          "completed_sessions": 0,
          "skipped_sessions": 1,
          "completeness": 50,
          "scholar_mark": null
        }
      },
      "quotas": [],
      "events": []
    }
    """

    static func decode<T: Decodable>(_ json: String, as type: T.Type) throws -> T {
        let data = Data(json.utf8)
        return try APIDecoding.makeJSONDecoder().decode(type, from: data)
    }
}
