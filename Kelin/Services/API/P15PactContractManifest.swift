import Foundation

enum P15PactContractManifest {
    static let taskID = "P15-T07"
    static let statusWord = "Mock完成-契约阻塞"
    static let capturedAt = "2026-09-12T14:50:00+08:00"

    static let liveOpenAPIURL = "http://192.168.100.212:8000/openapi.json"
    static let liveOpenAPISHA256 = "75f505f062674495cde0a3401ef82dcab3e278a4223119ca9e84b64863059bbd"
    static let documentReviewedSHA256 = "743b462becbdce5d2ea062632e776318277c05c36007bfa718867e40bad0bb27"
    static let previousSpeechDocumentSHA256 = "cdb52009a4ec253303a483f7a706d0439bc3fae8c728f146bbb7fa89fec71ae2"
    static let interviewBankSHA256 = "ece1b114f5017149ddf0b93bc46951f3858205ae0e038df3a9606ab151a7cab4"

    static let isLocked = false
    static let allowsClientScore = false
    static let allowsClientCompleteEndpoint = false
    static let allowsIndependentComplete = false
    static let liveRoutesMatchDocument = false

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
        "POST /api/v1/transcribe",
        "POST /api/v1/synthesize",
        "GET /health/live",
        "GET /health/ready",
    ]

    static let requiredEndpoints: [RequiredEndpoint] = [
        RequiredEndpoint(method: "POST", path: "/api/v1/pacts"),
        RequiredEndpoint(method: "POST", path: "/api/v1/pact-session"),
        RequiredEndpoint(method: "POST", path: "/api/v1/pact-answer"),
        RequiredEndpoint(method: "POST", path: "/api/v1/pact-skip"),
    ]

    static let forbiddenCompletePathFragments: [String] = [
        "/pacts/{id}/complete",
        "/pacts/{pact_id}/complete",
        "/pact-complete",
        "/pact/complete",
    ]

    static let requiredFixtureIDs: [String] = [
        "pact.create.success",
        "pact.session.success",
        "pact.answer.incremental",
        "pact.answer.finalized",
        "pact.skip.success",
    ]

    static let generatedFixtureIDs: [String] = [
        "pact.create.success",
        "pact.session.success",
        "pact.answer.incremental",
        "pact.answer.finalized",
        "pact.skip.success",
    ]

    static let missingCatalogLocks: [String] = [
        "live OpenAPI SHA mismatch",
        "POST /api/v1/pacts",
        "POST /api/v1/pact-session",
        "POST /api/v1/pact-answer",
        "POST /api/v1/pact-skip",
    ]

    static var missingEndpoints: [RequiredEndpoint] {
        requiredEndpoints.filter { endpoint in
            !presentPaths.contains(endpoint.signature)
        }
    }

    static var missingFixtureIDs: [String] {
        requiredFixtureIDs.filter { !generatedFixtureIDs.contains($0) }
    }

    static var liveHasPactWriteRoutes: Bool {
        missingEndpoints.isEmpty
    }

    static var liveHasForbiddenPactComplete: Bool {
        presentPaths.contains { path in
            let normalized = path.lowercased()
            return normalized.contains("pact") && normalized.contains("complete")
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
