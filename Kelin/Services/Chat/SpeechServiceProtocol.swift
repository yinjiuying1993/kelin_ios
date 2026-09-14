import Foundation

protocol SpeechServiceProtocol: Sendable {
    func transcribe(clientID: UUID, clip: VoiceClip) async throws -> TranscriptResult
    func synthesize(clientID: UUID, messageID: UUID) async throws -> SpeechAudioResult
}
