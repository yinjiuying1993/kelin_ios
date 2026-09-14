import Foundation

enum P16P20ContractManifest {
    static let taskID = "P16-P20"
    static let capturedAt = "2026-09-14T11:55:00+08:00"

    static let liveOpenAPIURL = "http://192.168.100.212:8000/openapi.json"
    static let liveOpenAPISHA256 = "614c0fd78437ce625aa5f184088736b27388369aba40835bf8326b92cc18fb70"
    static let documentReviewedSHA256 = "fed40c13c30d2203f20ed83c7ad208042c13f35e330d3491e407f22be0593230"

    static let liveHasFriendsRoutes = true
    static let liveHasPostcardRoutes = true
    static let liveHasDeviceRoute = true
    static let liveHasReportRoutes = true
    static let liveHasSpiritPatch = true
    static let liveHasAccountDelete = true
    static let liveHasRecallRoute = false
    static let liveHasDebugRoutes = false
    static let liveHasVisitCreate = false
    static let liveHasIdentityLinkREST = false

    static let publicSpiritProfileFields = ["id", "title", "stage", "public_marks", "status"]
    static let deviceResponseFields = ["device_id", "enabled", "updated_at"]
    static let accountDeleteConfirm = "DELETE_MY_ACCOUNT"
    static let debugResetConfirm = "RESET_MY_DEBUG_ACCOUNT"

    static let presentWritePaths: [String] = [
        "GET /api/v1/friends",
        "POST /api/v1/friends",
        "DELETE /api/v1/friends/{friend_id}",
        "GET /api/v1/postcards",
        "PATCH /api/v1/postcards/{postcard_id}/read",
        "POST /api/v1/devices",
        "GET /api/v1/report",
        "POST /api/v1/report/line",
        "PATCH /api/v1/spirit",
        "DELETE /api/v1/account",
    ]

    static let missingDocumentPaths: [String] = [
        "POST /api/v1/recall",
        "GET /api/v1/debug/usage",
    ]
}
