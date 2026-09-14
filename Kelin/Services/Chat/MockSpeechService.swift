import Foundation

actor MockSpeechService: SpeechServiceProtocol {
    var transcriptText = "亮着。今天还下雨了。"
    var error: AppError?

    func transcribe(clientID: UUID, clip: VoiceClip) async throws -> TranscriptResult {
        if let error {
            throw error
        }
        return TranscriptResult(
            text: transcriptText,
            durationMs: max(1, Int(clip.duration * 1_000)),
            language: "zh",
            providerRequestID: nil,
            patch: SessionPatch(
                snapshotVersion: 1,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                serverTime: Date()
            )
        )
    }

    func synthesize(clientID: UUID, messageID: UUID) async throws -> SpeechAudioResult {
        if let error {
            throw error
        }
        let remote = URL(string: "https://kelin.invalid/object/kelin-tts/tts/mock/\(messageID.uuidString.lowercased())/default.m4a?exp=1&sig=mock")!
        return SpeechAudioResult(
            audioURL: remote,
            playbackURL: remote,
            mime: "audio/mp4",
            durationMs: 1_000,
            expiresAt: Date().addingTimeInterval(600),
            cacheHit: false,
            patch: SessionPatch(
                snapshotVersion: 1,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                serverTime: Date()
            )
        )
    }
}
