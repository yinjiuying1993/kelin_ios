import Foundation

struct TranscriptResult: Equatable, Sendable {
    let text: String
    let durationMs: Int
    let language: String
    let providerRequestID: String?
    let patch: SessionPatch
}

struct SpeechAudioResult: Equatable, Sendable {
    let audioURL: URL
    let playbackURL: URL
    let mime: String
    let durationMs: Int
    let expiresAt: Date
    let cacheHit: Bool
    let patch: SessionPatch
}

struct VoiceClip: Equatable, Sendable {
    let data: Data
    let mimeType: String
    let duration: TimeInterval
}
