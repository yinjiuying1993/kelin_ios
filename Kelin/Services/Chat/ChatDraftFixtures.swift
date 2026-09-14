import Foundation

enum ChatDraftFixtures {
    // Source: kelin_server_technical_spec.md §10.1 (draft, Mock-only; OpenAPI SHA pending)

    static let ordinarySuccessEnvelope = """
    {
      "ok": true,
      "data": {
        "resource": {
          "type": "chat_turn",
          "generation_source": "stub",
          "user_message": {
            "id": "10000000-0000-4000-8000-000000000001",
            "content": "亮着。今天还下雨了。"
          },
          "spirit_message": {
            "id": "10000000-0000-4000-8000-000000000002",
            "content": "雨下得大的时候，屋檐下会很安静。"
          },
          "conversation_window_id": "40000000-0000-4000-8000-000000000001",
          "should_extract": false,
          "usage": { "input_units": 12, "output_units": 8 }
        },
        "patch": {
          "snapshot_version": 8,
          "spirit": null,
          "room": null,
          "onboarding": null
        }
      },
      "error": null,
      "request_id": "fixture-chat-ordinary",
      "server_time": "2026-09-10T08:00:02Z"
    }
    """
}
