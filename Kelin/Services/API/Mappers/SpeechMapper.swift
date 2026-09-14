import Foundation

enum SpeechMapper {
    static func normalizedAudioMIME(_ mimeType: String) -> String {
        mimeType
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: true)
            .first
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            ?? ""
    }

    static func isAllowedAudioMIME(_ mimeType: String) -> Bool {
        P14SpeechContractManifest.allowedAudioMIMETypes.contains(normalizedAudioMIME(mimeType))
    }

    static func mapTranscript(_ dto: TranscribeMutationResultDTO, serverTime: Date?) throws -> TranscriptResult {
        guard dto.resource.type == "transcript" else {
            throw AppError.decoding
        }

        let text = dto.resource.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw AppError.asrEmptyResult
        }
        guard (1...4_000).contains(text.count) else {
            throw AppError.decoding
        }
        guard (1...30_000).contains(dto.resource.durationMs) else {
            throw AppError.decoding
        }

        let patch = try SessionPatchMapper.attachingQuotas(
            try SessionPatchMapper.map(dto.patch, serverTime: serverTime),
            from: dto.quotas
        )

        return TranscriptResult(
            text: text,
            durationMs: dto.resource.durationMs,
            language: dto.resource.language,
            providerRequestID: dto.resource.providerRequestID,
            patch: patch
        )
    }

    static func makeSynthesizeRequest(clientID: UUID, messageID: UUID) -> SynthesizeRequestDTO {
        SynthesizeRequestDTO(
            clientID: clientID,
            messageID: messageID,
            voiceProfile: P14SpeechContractManifest.specVoiceProfileValues[0]
        )
    }

    static func mapSpeechAudio(
        _ dto: SynthesizeMutationResultDTO,
        apiBaseURL: URL,
        serverTime: Date?
    ) throws -> SpeechAudioResult {
        guard dto.resource.type == "speech_audio" else {
            throw AppError.decoding
        }
        guard dto.resource.mime == "audio/mp4" else {
            throw AppError.decoding
        }
        guard dto.resource.durationMs >= 1 else {
            throw AppError.decoding
        }
        guard let remoteURL = URL(string: dto.resource.audioURL) else {
            throw AppError.decoding
        }

        let patch = try SessionPatchMapper.attachingQuotas(
            try SessionPatchMapper.map(dto.patch, serverTime: serverTime),
            from: dto.quotas
        )

        return SpeechAudioResult(
            audioURL: remoteURL,
            playbackURL: VoiceRules.rewrittenPlaybackURL(remoteURL, apiBaseURL: apiBaseURL),
            mime: dto.resource.mime,
            durationMs: dto.resource.durationMs,
            expiresAt: dto.resource.expiresAt,
            cacheHit: dto.resource.cacheHit,
            patch: patch
        )
    }

    static func makeMultipartBody(clientID: UUID, audio: Data, mimeType: String) -> (boundary: String, body: Data) {
        let boundary = "kelin-\(UUID().uuidString.lowercased())"
        var body = Data()

        func append(_ value: String) {
            body.append(Data(value.utf8))
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"client_id\"\r\n\r\n")
        append("\(clientID.uuidString.lowercased())\r\n")
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.m4a\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(audio)
        append("\r\n--\(boundary)--\r\n")
        return (boundary, body)
    }
}
