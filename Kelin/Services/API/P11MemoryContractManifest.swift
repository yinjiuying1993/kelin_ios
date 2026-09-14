import Foundation

enum P11MemoryContractManifest {
    static let taskID = "P11-T05"
    static let statusWord = "待人工验收"
    static let capturedAt = "2026-09-11T10:30:00+08:00"

    static let liveOpenAPIURL = "http://192.168.100.212:8000/openapi.json"
    static let liveOpenAPISHA256 = "e873a20139df4d320fe134e61e0c9fba8146787f964f23f36d26dfd555a62a2e"
    static let documentReviewedSHA256 = "5aea0b23c6f4f8a49528acc05c8dd9b744a0bcee7a4c1c33332a509b8a9326d6"
    static let previousReviewedSHA256 = "733fdf37aa738451177d368c221a6e3b46a62efec626b4623dc8873d6ac1b661"

    static let isLocked = true

    static let presentPaths: [String] = [
        "GET /api/v1/bootstrap",
        "POST /api/v1/chat",
        "POST /api/v1/extract",
        "GET /api/v1/messages",
        "GET /api/v1/memories",
        "PATCH /api/v1/memories/{memory_id}",
        "DELETE /api/v1/memories/{memory_id}",
        "DELETE /api/v1/memories",
        "POST /api/v1/onboarding/complete",
        "POST /api/v1/spirits",
        "GET /health/live",
        "GET /health/ready",
    ]

    static let requiredEndpoints: [RequiredEndpoint] = [
        RequiredEndpoint(method: "GET", path: "/api/v1/memories"),
        RequiredEndpoint(method: "PATCH", path: "/api/v1/memories/{memory_id}"),
        RequiredEndpoint(method: "DELETE", path: "/api/v1/memories/{memory_id}"),
        RequiredEndpoint(method: "DELETE", path: "/api/v1/memories"),
    ]

    static let memoryPublicRequiredKeys: [String] = [
        "id",
        "type",
        "summary",
        "salience",
        "confidence",
        "status",
        "version",
        "created_at",
    ]

    static let memoryPublicTypeValues: [String] = [
        "preference",
        "knowledge",
        "emotion",
        "relation",
        "speech",
        "sight",
    ]

    static let memoryPublicStatusValues: [String] = [
        "active",
        "sealed",
        "deleted",
    ]

    static let requiredFixtureIDs: [String] = [
        "memories.list.success",
        "memories.list.business_error",
        "memories.list.missing_required_field",
        "memories.list.empty",
        "memories.list.first",
        "memories.list.middle",
        "memories.list.last",
        "memories.list.invalid_cursor",
        "memories.list.filter_cursor_invalidated",
        "memories.patch.success",
        "memories.patch.idempotency_conflict",
        "memories.patch.version_conflict",
        "memories.patch.not_found",
        "memories.patch.illegal_status",
        "memories.delete.success",
        "memories.clear.success",
    ]

    static let generatedFixtureIDs: [String] = [
        "memories.list.success",
        "memories.patch.success",
        "memories.clear.success",
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
