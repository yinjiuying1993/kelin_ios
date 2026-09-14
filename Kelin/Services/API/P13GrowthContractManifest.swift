import Foundation

enum P13GrowthContractManifest {
    static let taskID = "P13-T07"
    static let statusWord = "待人工验收"
    static let capturedAt = "2026-09-11T17:30:00+08:00"

    static let liveOpenAPIURL = "http://192.168.100.212:8000/openapi.json"
    static let liveOpenAPISHA256 = "84f1849d536485ea819e0863adc86b1e9a213229d7dd6dd81f0f3ca7cd2abc95"
    static let previousReviewedSHA256 = "84f1849d536485ea819e0863adc86b1e9a213229d7dd6dd81f0f3ca7cd2abc95"
    static let reviewedDocumentSHA256 = "4297869e18a29e1ac9933f620def66dcfc8c902a504d380459eb6bc7ba961092"

    static let isLocked = true
    static let allowsClientDelta = false

    static let presentPaths: [String] = [
        "GET /api/v1/bootstrap",
        "POST /api/v1/chat",
        "POST /api/v1/extract",
        "GET /api/v1/messages",
        "GET /api/v1/memories",
        "PATCH /api/v1/memories/{memory_id}",
        "DELETE /api/v1/memories/{memory_id}",
        "DELETE /api/v1/memories",
        "POST /api/v1/feed",
        "PATCH /api/v1/feeds/{feed_id}",
        "POST /api/v1/feeds/{feed_id}/complete",
        "POST /api/v1/feeds/{feed_id}/cancel",
        "POST /api/v1/storage/sight-upload-url",
        "POST /api/v1/moderate-sight",
        "POST /api/v1/onboarding/complete",
        "POST /api/v1/spirits",
        "GET /health/live",
        "GET /health/ready",
    ]

    static let specEventTypes: [String] = [
        "chat_completed",
        "feed_accepted",
        "promise_completed",
        "pact_answered",
        "pact_completed",
        "memory_added",
        "visit_completed",
        "returned_from_lost",
        "time_passed",
    ]

    static let liveObservedEventTypes: [String] = [
        "feed.accepted",
        "promise.completed",
    ]

    static let spiritStageValues: [String] = [
        "whelp",
        "formed",
        "awake",
    ]

    static let spiritStatusValues: [String] = [
        "home",
        "away",
        "study",
        "lost",
    ]

    static let specQuotaCapabilities: [String] = [
        "chat",
        "asr",
        "tts",
        "sight",
        "search",
        "food",
        "knowledge",
        "emotion",
        "visit",
        "pact",
    ]

    static let presentReadOnlySpiritKeys: [String] = [
        "stage",
        "status",
        "scholar_marks",
        "closeness",
        "curiosity",
        "sharpness",
        "nocturnal",
        "stubborn",
        "hunger",
        "energy",
        "mood",
        "bond",
    ]

    static let missingCatalogLocks: [String] = [
        "MutationEvent.type enum",
        "growth_events unique (source_type,source_id,event_type)",
        "QuotaUsage.capability enum",
        "daily_usage.reserved",
        "ai_usage",
    ]

    static let requiredFixtureIDs: [String] = [
        "growth.chat_completed.success",
        "growth.feed_accepted.success",
        "growth.promise_completed.success",
        "growth.duplicate_source",
        "growth.unknown_event",
        "growth.clamp_upper",
        "growth.clamp_lower",
        "evolution.formed.success",
        "evolution.formed.blocked",
        "evolution.awake.success",
        "quota.exceeded",
    ]

    static var generatedFixtureIDs: [String] {
        []
    }

    static var eventTypeConflicts: [String] {
        liveObservedEventTypes.filter { observed in
            let underscored = observed.replacingOccurrences(of: ".", with: "_")
            return specEventTypes.contains(underscored) && !specEventTypes.contains(observed)
        }
    }

    static var missingEventTypeEnum: Bool {
        true
    }
}
