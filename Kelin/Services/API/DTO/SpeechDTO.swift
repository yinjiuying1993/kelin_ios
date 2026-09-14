import Foundation

struct TranscriptResourceDTO: Decodable, Sendable, Equatable {
    let type: String
    let text: String
    let durationMs: Int
    let language: String
    let providerRequestID: String?

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case durationMs = "duration_ms"
        case language
        case providerRequestID = "provider_request_id"
    }
}

struct TranscribeMutationResultDTO: Decodable, Sendable, Equatable {
    let resource: TranscriptResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
}

struct SynthesizeRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let messageID: UUID
    let voiceProfile: String

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case messageID = "message_id"
        case voiceProfile = "voice_profile"
    }
}

struct SpeechAudioResourceDTO: Decodable, Sendable, Equatable {
    let type: String
    let audioURL: String
    let mime: String
    let durationMs: Int
    let expiresAt: Date
    let cacheHit: Bool

    enum CodingKeys: String, CodingKey {
        case type
        case audioURL = "audio_url"
        case mime
        case durationMs = "duration_ms"
        case expiresAt = "expires_at"
        case cacheHit = "cache_hit"
    }
}

struct SynthesizeMutationResultDTO: Decodable, Sendable, Equatable {
    let resource: SpeechAudioResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
}
