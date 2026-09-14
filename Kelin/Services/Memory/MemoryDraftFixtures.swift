import Foundation

enum MemoryDraftFixtures {
    static let memoryID = UUID(uuidString: "50000000-0000-4000-8000-000000000001")!
    static let sealedID = UUID(uuidString: "50000000-0000-4000-8000-000000000002")!
    static let deletedID = UUID(uuidString: "50000000-0000-4000-8000-000000000099")!

    static let preference = MemorySummary(
        id: memoryID,
        type: "preference",
        summary: "不要叫宝宝，要叫阿年",
        status: "active",
        createdAt: Date(timeIntervalSince1970: 1_778_086_400),
        version: 1,
        tags: ["name"],
        salience: 80,
        confidence: 0.9
    )

    static let sight = MemorySummary(
        id: UUID(uuidString: "50000000-0000-4000-8000-000000000002")!,
        type: "sight",
        summary: "雨夜里的一盏路灯",
        status: "active",
        createdAt: Date(timeIntervalSince1970: 1_778_000_000),
        version: 1,
        salience: 60,
        confidence: 0.7
    )

    static let knowledge = MemorySummary(
        id: UUID(uuidString: "50000000-0000-4000-8000-000000000003")!,
        type: "knowledge",
        summary: "STAR 法则",
        status: "active",
        createdAt: Date(timeIntervalSince1970: 1_777_913_600),
        version: 1,
        salience: 55,
        confidence: 0.8
    )

    static let s07Samples = [preference, sight, knowledge]

    static let listPageJSON = """
    {
      "items": [
        {
          "id": "50000000-0000-4000-8000-000000000001",
          "type": "preference",
          "summary": "不要叫宝宝，要叫阿年",
          "tags": ["name"],
          "salience": 80,
          "confidence": 0.9,
          "status": "active",
          "version": 1,
          "created_at": "2026-09-10T15:00:00Z"
        }
      ],
      "tombstones": [
        {
          "id": "50000000-0000-4000-8000-000000000099",
          "deleted_at": "2026-09-10T14:00:00Z"
        }
      ],
      "next_cursor": null,
      "has_more": false,
      "snapshot_at": "2026-09-11T00:00:00Z"
    }
    """

    static let tombstoneWithSummaryJSON = """
    {
      "id": "50000000-0000-4000-8000-000000000099",
      "deleted_at": "2026-09-10T14:00:00Z",
      "summary": "不该出现"
    }
    """

    static let correctPatchJSON = """
    {
      "resource": {
        "type": "memory",
        "id": "50000000-0000-4000-8000-000000000001",
        "version": 2,
        "status": "active"
      },
      "patch": {
        "snapshot_version": 12,
        "spirit": null,
        "memories_upsert": [
          {
            "id": "50000000-0000-4000-8000-000000000001",
            "type": "preference",
            "summary": "请叫我阿年",
            "tags": ["name"],
            "salience": 80,
            "confidence": 0.9,
            "status": "active",
            "version": 2,
            "created_at": "2026-09-10T15:00:00Z"
          }
        ],
        "memory_tombstones": []
      }
    }
    """

    static let clearPatchJSON = """
    {
      "resource": {
        "type": "memory_clear",
        "id": "60000000-0000-4000-8000-000000000001",
        "version": 1
      },
      "patch": {
        "snapshot_version": 13,
        "memories_upsert": [],
        "memory_tombstones": []
      }
    }
    """
}
