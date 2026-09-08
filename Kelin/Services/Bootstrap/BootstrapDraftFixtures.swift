import Foundation


enum BootstrapDraftFixtures {
    // Source: kelin_server_technical_spec.md §9.2 (draft, Mock-only; OpenAPI SHA pending)

    static let newUserEnvelope = """
    {
      "ok": true,
      "data": {
        "schema_version": 2,
        "snapshot_version": 0,
        "api_version": "v1",
        "spirit": null,
        "room": null,
        "onboarding": {
          "required": true,
          "step": 0,
          "total_steps": 5,
          "completed_at": null
        },
        "latest_memories": [],
        "unread_postcards": [],
        "active_pact": null,
        "report": {
          "status": "locked",
          "report_id": null,
          "eligibility": {
            "is_eligible": false,
            "eligible_at": "2026-09-14T00:00:00Z",
            "days_remaining": 7,
            "required_dialogue_rounds": 10,
            "completed_dialogue_rounds": 0,
            "dialogue_rounds_remaining": 10
          },
          "card": null
        },
        "quotas": [],
        "feature_flags": {
          "remote_search": true,
          "image_feed": true
        }
      },
      "error": null,
      "request_id": "req-bootstrap-new-user",
      "server_time": "2026-09-07T03:46:00Z"
    }
    """

    static let onboardingUserEnvelope = """
    {
      "ok": true,
      "data": {
        "schema_version": 2,
        "snapshot_version": 12,
        "api_version": "v1",
        "spirit": {
          "id": "00000000-0000-0000-0000-000000000101",
          "user_id": "00000000-0000-0000-0000-0000000000A1",
          "name": "未名",
          "egg": "warm",
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
          "version": 12,
          "away_until": null,
          "study_until": null,
          "last_interact_at": "2026-09-07T03:46:00Z",
          "created_at": "2026-09-07T03:46:00Z",
          "updated_at": "2026-09-07T03:46:00Z",
          "hatched_at": null,
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
          }
        },
        "room": {
          "weather": "cloudy",
          "layers": [],
          "letter": null,
          "pending_sight": null,
          "unread_footprint_count": 0,
          "updated_at": "2026-09-07T03:46:00Z"
        },
        "onboarding": {
          "required": true,
          "step": 3,
          "total_steps": 5,
          "completed_at": null
        },
        "latest_memories": [],
        "unread_postcards": [],
        "active_pact": null,
        "report": {
          "status": "locked",
          "report_id": null,
          "eligibility": {
            "is_eligible": false,
            "eligible_at": "2026-09-14T00:00:00Z",
            "days_remaining": 4,
            "required_dialogue_rounds": 10,
            "completed_dialogue_rounds": 3,
            "dialogue_rounds_remaining": 7
          },
          "card": null
        },
        "quotas": [
          {"capability": "chat", "used": 2, "limit": 100, "reset_at": "2026-09-08T00:00:00Z"}
        ],
        "feature_flags": {
          "remote_search": true,
          "image_feed": true
        }
      },
      "error": null,
      "request_id": "req-bootstrap-onboarding",
      "server_time": "2026-09-07T03:46:00Z"
    }
    """

    static let fullUserEnvelope = """
    {
      "ok": true,
      "data": {
        "schema_version": 2,
        "snapshot_version": 184,
        "api_version": "v1",
        "spirit": {
          "id": "00000000-0000-0000-0000-000000000201",
          "user_id": "00000000-0000-0000-0000-0000000000B1",
          "name": "雾生",
          "egg": "cold",
          "invite_code": "WXYZ6789",
          "closeness": 35,
          "curiosity": 45,
          "sharpness": 70,
          "nocturnal": 60,
          "stubborn": 55,
          "hunger": 72,
          "energy": 68,
          "mood": 55,
          "bond": 12,
          "stage": "formed",
          "status": "home",
          "scholar_marks": ["reader"],
          "version": 184,
          "away_until": null,
          "study_until": null,
          "last_interact_at": "2026-09-07T03:46:00Z",
          "created_at": "2026-08-30T03:46:00Z",
          "updated_at": "2026-09-07T03:46:00Z",
          "hatched_at": "2026-09-01T03:46:00Z",
          "preferences": {
            "tts_on": true,
            "push_on": false,
            "visit_on": true,
            "dnd_start": "23:00",
            "dnd_end": "08:00",
            "timezone": "Asia/Shanghai",
            "default_city": "上海",
            "location_weather_on": false,
            "remote_search_on": true
          }
        },
        "room": {
          "weather": "rain",
          "layers": [
            {"key": "floor", "variant": "default"}
          ],
          "letter": null,
          "pending_sight": null,
          "unread_footprint_count": 2,
          "updated_at": "2026-09-07T03:46:00Z"
        },
        "onboarding": {
          "required": false,
          "step": 5,
          "total_steps": 5,
          "completed_at": "2026-09-01T03:46:00Z"
        },
        "latest_memories": [],
        "unread_postcards": [],
        "active_pact": null,
        "report": {
          "status": "locked",
          "report_id": null,
          "eligibility": {
            "is_eligible": false,
            "eligible_at": "2026-09-14T00:00:00Z",
            "days_remaining": 4,
            "required_dialogue_rounds": 10,
            "completed_dialogue_rounds": 3,
            "dialogue_rounds_remaining": 7
          },
          "card": null
        },
        "quotas": [
          {"capability": "chat", "used": 12, "limit": 100, "reset_at": "2026-09-08T00:00:00Z"},
          {"capability": "tts", "used": 1, "limit": 20, "reset_at": "2026-09-08T00:00:00Z"}
        ],
        "feature_flags": {
          "remote_search": true,
          "image_feed": true
        }
      },
      "error": null,
      "request_id": "req-bootstrap-full-user",
      "server_time": "2026-09-07T03:46:00Z"
    }
    """

    static let unknownReportStatusEnvelope = """
    {
      "ok": true,
      "data": {
        "schema_version": 2,
        "snapshot_version": 1,
        "api_version": "v1",
        "spirit": null,
        "room": null,
        "onboarding": {
          "required": true,
          "step": 0,
          "total_steps": 5,
          "completed_at": null
        },
        "latest_memories": [],
        "unread_postcards": [],
        "active_pact": null,
        "report": {
          "status": "not-a-real-status",
          "report_id": null,
          "eligibility": {
            "is_eligible": false,
            "eligible_at": "2026-09-14T00:00:00Z",
            "days_remaining": 7,
            "required_dialogue_rounds": 10,
            "completed_dialogue_rounds": 0,
            "dialogue_rounds_remaining": 10
          },
          "card": null
        },
        "quotas": [],
        "feature_flags": {
          "remote_search": true,
          "image_feed": true
        }
      },
      "error": null,
      "request_id": "req-bootstrap-unknown-status",
      "server_time": "2026-09-07T03:46:00Z"
    }
    """

    static let missingRequiredFieldEnvelope = """
    {
      "ok": true,
      "data": {
        "snapshot_version": 1,
        "api_version": "v1",
        "spirit": null,
        "room": null,
        "onboarding": {
          "required": true,
          "step": 0,
          "total_steps": 5,
          "completed_at": null
        },
        "latest_memories": [],
        "unread_postcards": [],
        "active_pact": null,
        "report": {
          "status": "locked",
          "report_id": null,
          "eligibility": {
            "is_eligible": false,
            "eligible_at": "2026-09-14T00:00:00Z",
            "days_remaining": 7,
            "required_dialogue_rounds": 10,
            "completed_dialogue_rounds": 0,
            "dialogue_rounds_remaining": 10
          },
          "card": null
        },
        "quotas": [],
        "feature_flags": {
          "remote_search": true,
          "image_feed": true
        }
      },
      "error": null,
      "request_id": "req-bootstrap-missing-schema",
      "server_time": "2026-09-07T03:46:00Z"
    }
    """
}
