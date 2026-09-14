import Foundation

enum ExtractDraftFixtures {
    // Source: P08-P10 integration doc; live ids/version 以服务端为准。
    // OpenAPI SHA: f46da36ea05c7eb3a7d9a87ba9cd92c28ea4662a68c9986a9a41abcbcbe48843

    static let successEnvelope = """
    {
      "ok": true,
      "data": {
        "resource": {
          "status": "extracted",
          "memories": [
            {
              "id": "50000000-0000-4000-8000-000000000001",
              "type": "preference",
              "summary": "希望被叫阿年",
              "status": "active",
              "created_at": "2026-09-10T08:10:00Z"
            }
          ],
          "style_samples": []
        },
        "patch": {
          "snapshot_version": 10,
          "spirit": null,
          "room": null,
          "onboarding": null,
          "memories_upsert": [
            {
              "id": "50000000-0000-4000-8000-000000000001",
              "type": "preference",
              "summary": "希望被叫阿年",
              "status": "active",
              "created_at": "2026-09-10T08:10:00Z"
            }
          ]
        }
      },
      "error": null,
      "request_id": "fixture-extract-success",
      "server_time": "2026-09-10T08:10:01Z"
    }
    """
}
