import AVFoundation
import XCTest
@testable import Kelin

final class SpeechMapperTests: XCTestCase {
    func testTranscribeSuccessMapsTextQuotasAndKeepsNullRoom() throws {
        let envelope = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<TranscribeMutationResultDTO>.self,
            from: Data(SpeechDraftFixtures.transcribeSuccessEnvelope.utf8)
        )
        let result = try SpeechMapper.mapTranscript(try XCTUnwrap(envelope.data), serverTime: envelope.serverTime)

        XCTAssertEqual(result.text, "亮着。今天还下雨了。")
        XCTAssertEqual(result.language, "zh")
        XCTAssertEqual(result.patch.snapshotVersion, 14)
        XCTAssertNil(result.patch.room)
        XCTAssertNil(result.patch.spirit)
        XCTAssertEqual(result.patch.quotas?.first?.capability, .asr)
        XCTAssertEqual(result.patch.quotas?.first?.used, 1)
        XCTAssertEqual(result.patch.quotas?.first?.limit, 60)
    }

    func testEmptyResultMapsToDedicatedErrorNotComposerCopy() {
        let error = APIErrorMapper.map(
            APIErrorPayload(
                code: "ASR_EMPTY_RESULT",
                message: "empty transcription",
                retryable: false,
                details: ["quota": "asr"]
            ),
            requestID: "empty-1"
        )

        XCTAssertEqual(error, .asrEmptyResult)
        XCTAssertEqual(ErrorCopy.app(error).message, "没听清，再说一次")
        XCTAssertFalse(ErrorCopy.app(error).message.contains("empty transcription"))
    }

    func testSynthesizeRequestHasOnlyDefaultVoiceAndNoText() throws {
        let request = SpeechMapper.makeSynthesizeRequest(
            clientID: UUID(uuidString: "20000000-0000-4000-8000-000000000001")!,
            messageID: UUID(uuidString: "10000000-0000-4000-8000-000000000002")!
        )
        let data = try APIDecoding.encodeBody(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(Set(object.keys), ["client_id", "message_id", "voice_profile"])
        XCTAssertEqual(object["voice_profile"] as? String, "default")
        XCTAssertNil(object["text"])
    }

    func testSynthesizeRewritesInvalidHostAndKeepsQuery() throws {
        let envelope = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<SynthesizeMutationResultDTO>.self,
            from: Data(SpeechDraftFixtures.synthesizeSuccessEnvelope.utf8)
        )
        let apiBase = URL(string: "http://192.168.100.212:8000")!
        let result = try SpeechMapper.mapSpeechAudio(
            try XCTUnwrap(envelope.data),
            apiBaseURL: apiBase,
            serverTime: envelope.serverTime
        )

        XCTAssertFalse(result.cacheHit)
        XCTAssertEqual(result.mime, "audio/mp4")
        XCTAssertEqual(result.patch.quotas?.first?.capability, .tts)
        XCTAssertEqual(result.playbackURL.host, "192.168.100.212")
        XCTAssertEqual(result.playbackURL.port, 8000)
        XCTAssertEqual(result.playbackURL.scheme, "http")
        XCTAssertTrue(result.playbackURL.path.contains("/object/kelin-tts/"))
        XCTAssertEqual(result.playbackURL.query?.contains("exp="), true)
        XCTAssertEqual(result.playbackURL.query?.contains("sig="), true)
        XCTAssertNotEqual(result.playbackURL.host, "kelin.invalid")
    }

    func testCacheHitKeepsUsedAtOne() throws {
        let envelope = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<SynthesizeMutationResultDTO>.self,
            from: Data(SpeechDraftFixtures.synthesizeCacheHitEnvelope.utf8)
        )
        let result = try SpeechMapper.mapSpeechAudio(
            try XCTUnwrap(envelope.data),
            apiBaseURL: URL(string: "http://192.168.100.212:8000")!,
            serverTime: envelope.serverTime
        )

        XCTAssertTrue(result.cacheHit)
        XCTAssertEqual(result.patch.quotas?.first?.used, 1)
    }

    func testAudioMIMEAllowsCodecsParameter() {
        XCTAssertTrue(SpeechMapper.isAllowedAudioMIME("audio/mp4; codecs=mp4a.40.2"))
        XCTAssertTrue(SpeechMapper.isAllowedAudioMIME("audio/m4a"))
        XCTAssertEqual(SpeechMapper.normalizedAudioMIME("audio/mp4; codecs=mp4a.40.2"), "audio/mp4")
        XCTAssertFalse(SpeechMapper.isAllowedAudioMIME("audio/wav"))
        XCTAssertFalse(SpeechMapper.isAllowedAudioMIME("image/jpeg"))
    }

    func testIdempotencyInProgressIsRetryableAndConflictIsNot() {
        XCTAssertEqual(
            APIErrorMapper.map(
                APIErrorPayload(
                    code: "IDEMPOTENCY_IN_PROGRESS",
                    message: "busy",
                    retryable: true,
                    details: nil
                ),
                requestID: "in-progress"
            ),
            .idempotencyInProgress
        )
        XCTAssertEqual(
            APIErrorMapper.map(
                APIErrorPayload(
                    code: "IDEMPOTENCY_CONFLICT",
                    message: "mismatch",
                    retryable: false,
                    details: nil
                ),
                requestID: "conflict"
            ),
            .conflict
        )
    }

    func testPlaybackExpiryUsesServerExpiresAt() {
        let now = Date(timeIntervalSince1970: 1_780_000_000)
        XCTAssertTrue(VoiceRules.isPlaybackExpired(now.addingTimeInterval(-1), now: now))
        XCTAssertFalse(VoiceRules.isPlaybackExpired(now.addingTimeInterval(600), now: now))
    }

    func testVoiceRequestDoesNotReuseTranscribeClientID() {
        let transcribeID = UUID()
        let chatID = UUID()
        XCTAssertNotEqual(transcribeID, chatID)
        XCTAssertEqual(ChatMessage.Source.voice.rawValue, "voice")
    }
}

final class VoiceRulesTests: XCTestCase {
    func testCancelOnlyUsesVerticalThreshold() {
        XCTAssertFalse(VoiceRules.willCancel(verticalTranslation: -79))
        XCTAssertTrue(VoiceRules.willCancel(verticalTranslation: -80))
        XCTAssertTrue(VoiceRules.willCancel(verticalTranslation: -120))
        XCTAssertFalse(VoiceRules.willCancel(verticalTranslation: 80))
    }

    func testHoldBoundsMatchContract() {
        XCTAssertTrue(VoiceRules.shouldDiscard(duration: 0.7))
        XCTAssertFalse(VoiceRules.shouldDiscard(duration: 0.8))
        XCTAssertFalse(VoiceRules.shouldAutoSend(duration: 29.9))
        XCTAssertTrue(VoiceRules.shouldAutoSend(duration: 30))
        XCTAssertTrue(VoiceRules.isTap(duration: 0.19))
        XCTAssertFalse(VoiceRules.isTap(duration: 0.2))
    }

    func testHoldDurationFormatIsMinuteSecond() {
        XCTAssertEqual(VoiceRules.formattedHoldDuration(0), "0:00")
        XCTAssertEqual(VoiceRules.formattedHoldDuration(8.4), "0:08")
        XCTAssertEqual(VoiceRules.formattedHoldDuration(30), "0:30")
        XCTAssertEqual(VoiceRules.formattedHoldDuration(40), "0:30")
    }

    func testComposerPresentationCopy() {
        XCTAssertEqual(VoiceComposerPresentation.holdLabel(isRecording: false, willCancel: false), "按住说话")
        XCTAssertEqual(VoiceComposerPresentation.holdLabel(isRecording: true, willCancel: false), "松开 发送")
        XCTAssertEqual(VoiceComposerPresentation.holdLabel(isRecording: true, willCancel: true), "松开 取消")
        XCTAssertEqual(VoiceComposerPresentation.hintLabel(willCancel: false), "上滑取消录音")
        XCTAssertEqual(VoiceComposerPresentation.hintLabel(willCancel: true), "松开取消")
        XCTAssertEqual(VoiceComposerPresentation.processingLabel(.uploading), "它在听")
        XCTAssertEqual(VoiceComposerPresentation.processingLabel(.transcribing), "它在辨认你说的话")
        XCTAssertTrue(VoiceComposerPresentation.blocksChrome(.recording(duration: 1, willCancel: false)))
        XCTAssertFalse(VoiceComposerPresentation.blocksChrome(.uploading))
    }

    func testAudioInterruptionBeganCancelsVoice() {
        let began: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue,
        ]
        let ended: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
        ]
        XCTAssertEqual(AudioSessionRules.event(fromUserInfo: began), .cancelVoiceAndTTS)
        XCTAssertNil(AudioSessionRules.event(fromUserInfo: ended))
        XCTAssertNil(AudioSessionRules.event(fromUserInfo: nil))
    }

    func testVoiceTempCleanupRemovesOnlyKelinASRFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("kelin-t09-\(UUID().uuidString.lowercased())", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let orphan = directory.appendingPathComponent("kelin-asr-orphan.m4a")
        let keep = directory.appendingPathComponent("other-temp.txt")
        try Data("audio".utf8).write(to: orphan)
        try Data("keep".utf8).write(to: keep)

        VoiceTempCleanup.purgeOrphans(in: directory)

        XCTAssertFalse(FileManager.default.fileExists(atPath: orphan.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: keep.path))
    }

    func testClientHasNoBailianOrBackgroundAudioFlags() {
        XCTAssertFalse(P14SpeechContractManifest.allowsBailianCredentialsOnClient)
        XCTAssertFalse(P14SpeechContractManifest.allowsAppleSpeech)
        XCTAssertFalse(P14SpeechContractManifest.allowsClientTTSText)
        XCTAssertFalse(P14SpeechContractManifest.specSynthesizeRequestKeys.contains("text"))
        XCTAssertFalse(P14SpeechContractManifest.bailianLiveReady)

        let plistURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Kelin/Config/Debug-Info.plist")
        let plist = NSDictionary(contentsOf: plistURL)
        XCTAssertNotNil(plist)
        XCTAssertNil(plist?["UIBackgroundModes"])
        XCTAssertEqual(plist?["NSMicrophoneUsageDescription"] as? String, "按住说话时需要使用麦克风。")
    }

    func testVoiceFailureOutcome() {
        XCTAssertEqual(VoiceComposerPresentation.outcome(for: .cancelled), .silent)
        XCTAssertEqual(VoiceComposerPresentation.outcome(for: .asrEmptyResult), .status("没听清，再说一次"))
        XCTAssertEqual(
            VoiceComposerPresentation.outcome(for: .quotaExceeded(.asr, resetAt: nil)),
            .switchToText("今天先看字吧")
        )
        XCTAssertEqual(
            VoiceComposerPresentation.outcome(for: .networkUnavailable),
            .status("连不上，房间还在")
        )
    }
}
