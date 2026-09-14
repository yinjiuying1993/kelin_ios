import Foundation

enum P12FeedContractManifest {
    static let taskID = "P12-T08"
    static let statusWord = "待人工验收"
    static let capturedAt = "2026-09-11T14:20:00+08:00"

    static let liveOpenAPIURL = "http://192.168.100.212:8000/openapi.json"
    static let liveOpenAPISHA256 = "84f1849d536485ea819e0863adc86b1e9a213229d7dd6dd81f0f3ca7cd2abc95"
    static let documentReviewedSHA256 = "4297869e18a29e1ac9933f620def66dcfc8c902a504d380459eb6bc7ba961092"
    static let previousReviewedSHA256 = "e873a20139df4d320fe134e61e0c9fba8146787f964f23f36d26dfd555a62a2e"

    static let isLocked = true
    static let photoLiveReady = false

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

    static let requiredEndpoints: [RequiredEndpoint] = [
        RequiredEndpoint(method: "POST", path: "/api/v1/feed"),
        RequiredEndpoint(method: "PATCH", path: "/api/v1/feeds/{feed_id}"),
        RequiredEndpoint(method: "POST", path: "/api/v1/feeds/{feed_id}/complete"),
        RequiredEndpoint(method: "POST", path: "/api/v1/feeds/{feed_id}/cancel"),
        RequiredEndpoint(method: "POST", path: "/api/v1/storage/sight-upload-url"),
        RequiredEndpoint(method: "POST", path: "/api/v1/moderate-sight"),
    ]

    static let requiredKinds: [String] = [
        "food",
        "knowledge",
        "emotion",
        "promise",
        "sight",
    ]

    static let requiredStatuses: [String] = [
        "pending",
        "processing",
        "accepted",
        "rejected",
        "cancelled",
    ]

    static let locationCategories: [String] = [
        "landmark",
        "park",
        "cafe",
        "school",
        "workplace",
        "other",
    ]

    static let sightPropWhitelist: [String] = [
        "lamp",
        "plant",
        "book",
        "object",
        "other",
    ]

    static let requiredFixtureIDs: [String] = [
        "feed.food.success",
        "feed.knowledge.success",
        "feed.emotion.success",
        "feed.promise.success",
        "sight.location.success",
        "sight.location.privacy_rejected",
        "promise.edit.success",
        "promise.complete.success",
        "promise.cancel.success",
        "sight.upload.success",
        "sight.moderate.success",
    ]

    static let generatedFixtureIDs: [String] = [
        "feed.food.success",
        "feed.knowledge.success",
        "feed.emotion.success",
        "feed.promise.success",
        "sight.location.success",
        "sight.location.privacy_rejected",
        "promise.edit.success",
        "promise.complete.success",
        "promise.cancel.success",
        "sight.upload.success",
    ]

    static var missingEndpoints: [RequiredEndpoint] {
        requiredEndpoints.filter { endpoint in
            !presentPaths.contains(endpoint.signature)
        }
    }

    struct RequiredEndpoint: Equatable, Sendable {
        let method: String
        let path: String

        var signature: String {
            "\(method) \(path)"
        }
    }
}
