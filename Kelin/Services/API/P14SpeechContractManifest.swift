import Foundation

enum P14SpeechContractManifest {
    static let taskID = "P14-T09"
    static let statusWord = "模拟器完成-待真机"
    static let capturedAt = "2026-09-12T11:30:00+08:00"

    static let liveOpenAPIURL = "http://192.168.100.212:8000/openapi.json"
    static let liveOpenAPISHA256 = "75f505f062674495cde0a3401ef82dcab3e278a4223119ca9e84b64863059bbd"
    static let documentReviewedSHA256 = "cdb52009a4ec253303a483f7a706d0439bc3fae8c728f146bbb7fa89fec71ae2"
    static let previousReviewedSHA256 = "84f1849d536485ea819e0863adc86b1e9a213229d7dd6dd81f0f3ca7cd2abc95"

    static let isLocked = true
    static let allowsAppleSpeech = false
    static let allowsBailianCredentialsOnClient = false
    static let allowsClientTTSText = false
    static let allowsResultInComposer = false
    static let documentSaysServerAliasConfigured = true
    static let bailianLiveReady = false

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
        RequiredEndpoint(method: "POST", path: "/api/v1/transcribe"),
        RequiredEndpoint(method: "POST", path: "/api/v1/synthesize"),
    ]

    static let specTranscribeMultipartFields: [String] = [
        "client_id",
        "audio",
    ]

    static let specTranscribeResourceKeys: [String] = [
        "text",
        "duration_ms",
        "language",
        "provider_request_id",
    ]

    static let specSynthesizeRequestKeys: [String] = [
        "client_id",
        "message_id",
        "voice_profile",
    ]

    static let specSynthesizeResourceKeys: [String] = [
        "audio_url",
        "mime",
        "duration_ms",
        "expires_at",
        "cache_hit",
    ]

    static let specVoiceProfileValues: [String] = [
        "default",
    ]

    static let allowedAudioMIMETypes: [String] = [
        "audio/mp4",
        "audio/m4a",
        "audio/x-m4a",
        "audio/aac",
    ]

    static let specAllowedContainerHints: [String] = [
        "m4a",
        "aac",
    ]

    static let specMaxAudioBytes = 5_242_880
    static let specMaxAudioSeconds = 30
    static let specMinHoldSeconds = 0.8
    static let specCancelDistancePoints = 80
    static let specASRClientTimeoutSeconds = 28
    static let specTTSClientTimeoutSeconds = 23
    static let specASRDailyLimit = 60
    static let specTTSDailyLimit = 20
    static let specTTSCacheHours = 24
    static let specTTSMaxHanCharacters = 200

    static let specEmptyResultCodes: [String] = [
        "ASR_EMPTY_RESULT",
        "INVALID_INPUT",
    ]

    static let missingCatalogLocks: [String] = []

    static let requiredFixtureIDs: [String] = [
        "speech.transcribe.success",
        "speech.transcribe.empty",
        "speech.synthesize.success",
        "speech.synthesize.cache_hit",
    ]

    static let generatedFixtureIDs: [String] = [
        "speech.transcribe.success",
        "speech.transcribe.empty",
        "speech.synthesize.success",
        "speech.synthesize.cache_hit",
    ]

    static var missingEndpoints: [RequiredEndpoint] {
        requiredEndpoints.filter { endpoint in
            !presentPaths.contains(endpoint.signature)
        }
    }

    static var missingFixtureIDs: [String] {
        requiredFixtureIDs.filter { !generatedFixtureIDs.contains($0) }
    }

    struct RequiredEndpoint: Equatable, Sendable {
        let method: String
        let path: String

        var signature: String {
            "\(method) \(path)"
        }
    }
}
