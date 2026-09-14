import Foundation

enum FeedDraftFixtures {
    static let foodID = UUID(uuidString: "61000000-0000-4000-8000-000000000001")!
    static let knowledgeMemoryID = UUID(uuidString: "61000000-0000-4000-8000-000000000010")!
    static let promiseID = UUID(uuidString: "61000000-0000-4000-8000-000000000020")!
    static let locationID = UUID(uuidString: "61000000-0000-4000-8000-000000000030")!
    static let uploadSessionID = UUID(uuidString: "61000000-0000-4000-8000-000000000040")!
    static let eventID = UUID(uuidString: "61000000-0000-4000-8000-000000000050")!

    static let foodSuccessJSON = """
    {
      "resource": {
        "type": "feed",
        "id": "61000000-0000-4000-8000-000000000001",
        "version": 1,
        "kind": "food",
        "status": "accepted"
      },
      "patch": {
        "snapshot_version": 12
      },
      "quotas": [
        {
          "capability": "food",
          "used": 1,
          "limit": 3,
          "reset_at": "2026-09-12T00:00:00Z"
        }
      ],
      "events": [
        {
          "id": "61000000-0000-4000-8000-000000000050",
          "type": "feed.accepted",
          "occurred_at": "2026-09-11T06:00:00Z"
        }
      ]
    }
    """

    static let knowledgeSuccessJSON = """
    {
      "resource": {
        "type": "feed",
        "id": "61000000-0000-4000-8000-000000000002",
        "version": 1,
        "kind": "knowledge",
        "status": "accepted"
      },
      "patch": {
        "snapshot_version": 13,
        "memories_upsert": [
          {
            "id": "61000000-0000-4000-8000-000000000010",
            "type": "knowledge",
            "summary": "STAR 法则",
            "salience": 40,
            "confidence": 0.8,
            "status": "active",
            "version": 1,
            "created_at": "2026-09-11T06:00:00Z"
          }
        ]
      },
      "quotas": [],
      "events": []
    }
    """

    static let locationRejectedJSON = """
    {
      "resource": {
        "type": "feed",
        "id": "61000000-0000-4000-8000-000000000030",
        "version": 1,
        "kind": "sight",
        "status": "rejected"
      },
      "patch": {
        "snapshot_version": 14
      },
      "quotas": [
        {
          "capability": "sight",
          "used": 1,
          "limit": 2,
          "reset_at": "2026-09-12T00:00:00Z"
        }
      ],
      "events": []
    }
    """

    static let uploadSuccessJSON = """
    {
      "upload_session_id": "61000000-0000-4000-8000-000000000040",
      "method": "PUT",
      "url": "https://kelin.invalid/put",
      "headers": {
        "content-type": "image/jpeg"
      },
      "object_path": "sight-temp/11111111-1111-4111-8111-111111111111/22222222-2222-4222-8222-222222222222/33333333-3333-4333-8333-333333333333.jpg",
      "expires_at": "2026-09-11T06:10:00Z",
      "max_size_bytes": 5242880
    }
    """

    static let promiseCompleteJSON = """
    {
      "resource": {
        "type": "feed",
        "id": "61000000-0000-4000-8000-000000000020",
        "version": 2,
        "kind": "promise",
        "status": "accepted",
        "promise_status": "completed"
      },
      "patch": {
        "snapshot_version": 15
      },
      "quotas": [],
      "events": [
        {
          "id": "61000000-0000-4000-8000-000000000051",
          "type": "promise.completed",
          "occurred_at": "2026-09-11T06:00:00Z"
        }
      ]
    }
    """
}
