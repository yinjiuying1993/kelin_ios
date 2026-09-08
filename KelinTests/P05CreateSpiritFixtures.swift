import Foundation
@testable import Kelin

enum P05CreateSpiritFixtures {
    // Source: kelin_server_technical_spec.md §9.3 + §5.2 (draft, Mock-only; OpenAPI SHA pending)

    static func successEnvelope(egg: EggType) -> String {
        let traits = traitsJSON(for: egg)
        return """
        {
          "ok": true,
          "data": {
            "resource": {
              "type": "spirit",
              "id": "00000000-0000-0000-0000-000000000101",
              "version": 1
            },
            "patch": {
              "snapshot_version": 1,
              "spirit": {
                "id": "00000000-0000-0000-0000-000000000101",
                "user_id": "00000000-0000-0000-0000-0000000000A1",
                "name": "未名",
                "egg": "\(egg.rawValue)",
                "invite_code": "ABCD2345",
                \(traits)
                "hunger": 80,
                "energy": 80,
                "mood": 60,
                "bond": 0,
                "stage": "whelp",
                "status": "home",
                "scholar_marks": [],
                "version": 1,
                "away_until": null,
                "study_until": null,
                "last_interact_at": "2026-09-07T03:46:00Z",
                "created_at": "2026-09-07T03:46:00Z",
                "updated_at": "2026-09-07T03:46:00Z",
                "hatched_at": null
              },
              "preferences": {
                "tts_on": false,
                "push_on": false,
                "visit_on": true,
                "dnd_start": "23:00",
                "dnd_end": "08:00",
                "timezone": "Asia/Shanghai",
                "default_city": null,
                "location_weather_on": false,
                "remote_search_on": true
              },
              "onboarding": {
                "required": true,
                "step": 0,
                "total_steps": 5,
                "completed_at": null
              }
            }
          },
          "error": null,
          "request_id": "req-create-spirit-\(egg.rawValue)",
          "server_time": "2026-09-07T03:46:00Z"
        }
        """
    }

    static let businessErrorEnvelope = """
    {
      "ok": false,
      "data": null,
      "error": {
        "code": "IDEMPOTENCY_CONFLICT",
        "message": "conflict",
        "retryable": false,
        "details": null
      },
      "request_id": "req-idempotency-conflict",
      "server_time": "2026-09-07T03:46:00Z"
    }
    """

    static let missingRequiredFieldEnvelope = """
    {
      "ok": true,
      "data": {
        "resource": {
          "type": "spirit",
          "id": "00000000-0000-0000-0000-000000000101",
          "version": 1
        },
        "patch": {
          "snapshot_version": 1,
          "spirit": {
            "id": "00000000-0000-0000-0000-000000000101",
            "user_id": "00000000-0000-0000-0000-0000000000A1",
            "name": "未名",
            "invite_code": "ABCD2345",
            "closeness": 65,
            "curiosity": 55,
            "sharpness": 35,
            "nocturnal": 40,
            "stubborn": 40,
            "hunger": 80,
            "energy": 80,
            "mood": 60,
            "bond": 0,
            "stage": "whelp",
            "status": "home",
            "scholar_marks": [],
            "version": 1,
            "away_until": null,
            "study_until": null,
            "last_interact_at": "2026-09-07T03:46:00Z",
            "created_at": "2026-09-07T03:46:00Z",
            "updated_at": "2026-09-07T03:46:00Z",
            "hatched_at": null
          },
          "onboarding": {
            "required": true,
            "step": 0,
            "total_steps": 5,
            "completed_at": null
          }
        }
      },
      "error": null,
      "request_id": "req-missing-egg",
      "server_time": "2026-09-07T03:46:00Z"
    }
    """

    private static func traitsJSON(for egg: EggType) -> String {
        switch egg {
        case .warm:
            """
            "closeness": 65,
            "curiosity": 55,
            "sharpness": 35,
            "nocturnal": 40,
            "stubborn": 40,
            """
        case .cold:
            """
            "closeness": 35,
            "curiosity": 45,
            "sharpness": 70,
            "nocturnal": 60,
            "stubborn": 55,
            """
        case .wild:
            """
            "closeness": 50,
            "curiosity": 50,
            "sharpness": 50,
            "nocturnal": 50,
            "stubborn": 50,
            """
        }
    }
}
