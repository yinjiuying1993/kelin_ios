import Foundation

enum SpeechDraftFixtures {
    static let transcribeSuccessEnvelope = """
    {
      "ok": true,
      "data": {
        "resource": {
          "type": "transcript",
          "text": "亮着。今天还下雨了。",
          "duration_ms": 1800,
          "language": "zh",
          "provider_request_id": null
        },
        "patch": {
          "snapshot_version": 14,
          "spirit": null,
          "room": null,
          "onboarding": null
        },
        "quotas": [
          {
            "capability": "asr",
            "used": 1,
            "limit": 60,
            "reset_at": "2026-09-12T16:00:00Z"
          }
        ]
      },
      "error": null,
      "request_id": "fixture-transcribe-success",
      "server_time": "2026-09-12T02:00:00Z"
    }
    """

    static let transcribeEmptyEnvelope = """
    {
      "ok": false,
      "data": null,
      "error": {
        "code": "ASR_EMPTY_RESULT",
        "message": "empty transcription",
        "retryable": false,
        "details": {"quota": "asr"}
      },
      "request_id": "fixture-transcribe-empty",
      "server_time": "2026-09-12T02:00:01Z"
    }
    """

    static let synthesizeSuccessEnvelope = """
    {
      "ok": true,
      "data": {
        "resource": {
          "type": "speech_audio",
          "audio_url": "https://kelin.invalid/object/kelin-tts/tts/00000000-0000-4000-8000-0000000000a1/10000000-0000-4000-8000-000000000002/default.m4a?exp=1780000000&sig=abc",
          "mime": "audio/mp4",
          "duration_ms": 2400,
          "expires_at": "2026-09-12T02:10:00Z",
          "cache_hit": false
        },
        "patch": {
          "snapshot_version": 15,
          "spirit": null,
          "room": null
        },
        "quotas": [
          {
            "capability": "tts",
            "used": 1,
            "limit": 20,
            "reset_at": "2026-09-12T16:00:00Z"
          }
        ]
      },
      "error": null,
      "request_id": "fixture-synthesize-success",
      "server_time": "2026-09-12T02:00:02Z"
    }
    """

    static let synthesizeCacheHitEnvelope = """
    {
      "ok": true,
      "data": {
        "resource": {
          "type": "speech_audio",
          "audio_url": "https://kelin.invalid/object/kelin-tts/tts/00000000-0000-4000-8000-0000000000a1/10000000-0000-4000-8000-000000000002/default.m4a?exp=1780000600&sig=def",
          "mime": "audio/mp4",
          "duration_ms": 2400,
          "expires_at": "2026-09-12T02:20:00Z",
          "cache_hit": true
        },
        "patch": {
          "snapshot_version": 15,
          "spirit": null,
          "room": null
        },
        "quotas": [
          {
            "capability": "tts",
            "used": 1,
            "limit": 20,
            "reset_at": "2026-09-12T16:00:00Z"
          }
        ]
      },
      "error": null,
      "request_id": "fixture-synthesize-cache",
      "server_time": "2026-09-12T02:00:03Z"
    }
    """
}
