import Foundation

actor APISpeechService: SpeechServiceProtocol {
    private let client: any APIClientProtocol
    private let apiBaseURL: URL

    init(client: any APIClientProtocol, apiBaseURL: URL) {
        self.client = client
        self.apiBaseURL = apiBaseURL
    }

    func transcribe(clientID: UUID, clip: VoiceClip) async throws -> TranscriptResult {
        try await sendTranscribe(clientID: clientID, clip: clip, allowInProgressRetry: true)
    }

    func synthesize(clientID: UUID, messageID: UUID) async throws -> SpeechAudioResult {
        try await sendSynthesize(clientID: clientID, messageID: messageID, allowInProgressRetry: true)
    }

    private func sendTranscribe(
        clientID: UUID,
        clip: VoiceClip,
        allowInProgressRetry: Bool
    ) async throws -> TranscriptResult {
        guard SpeechMapper.isAllowedAudioMIME(clip.mimeType) else {
            throw AppError.invalidInput
        }
        guard (1...P14SpeechContractManifest.specMaxAudioBytes).contains(clip.data.count) else {
            throw AppError.invalidInput
        }

        let multipart = SpeechMapper.makeMultipartBody(
            clientID: clientID,
            audio: clip.data,
            mimeType: SpeechMapper.normalizedAudioMIME(clip.mimeType)
        )

        do {
            let result = try await client.sendWithMetadata(
                .postMultipart(
                    "/transcribe",
                    body: multipart.body,
                    boundary: multipart.boundary,
                    timeout: APIEndpoint.transcribePOSTTimeout
                ),
                responseType: TranscribeMutationResultDTO.self
            )
            return try SpeechMapper.mapTranscript(result.payload, serverTime: result.serverTime)
        } catch AppError.idempotencyInProgress where allowInProgressRetry {
            try await Task.sleep(for: .milliseconds(800))
            return try await sendTranscribe(clientID: clientID, clip: clip, allowInProgressRetry: false)
        }
    }

    private func sendSynthesize(
        clientID: UUID,
        messageID: UUID,
        allowInProgressRetry: Bool
    ) async throws -> SpeechAudioResult {
        let request = SpeechMapper.makeSynthesizeRequest(clientID: clientID, messageID: messageID)
        let body = try APIDecoding.encodeBody(request)
        do {
            let result = try await client.sendWithMetadata(
                .post("/synthesize", body: body, timeout: APIEndpoint.synthesizePOSTTimeout),
                responseType: SynthesizeMutationResultDTO.self
            )
            return try SpeechMapper.mapSpeechAudio(
                result.payload,
                apiBaseURL: apiBaseURL,
                serverTime: result.serverTime
            )
        } catch AppError.idempotencyInProgress where allowInProgressRetry {
            try await Task.sleep(for: .milliseconds(800))
            return try await sendSynthesize(
                clientID: clientID,
                messageID: messageID,
                allowInProgressRetry: false
            )
        }
    }
}
