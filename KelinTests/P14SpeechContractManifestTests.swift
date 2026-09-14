import XCTest
@testable import Kelin

final class P14SpeechContractManifestTests: XCTestCase {
    func testLiveOpenAPISHAIsFullLengthHex() {
        XCTAssertEqual(P14SpeechContractManifest.liveOpenAPISHA256.count, 64)
        XCTAssertTrue(
            P14SpeechContractManifest.liveOpenAPISHA256.unicodeScalars.allSatisfy {
                CharacterSet(charactersIn: "0123456789abcdef").contains($0)
            }
        )
    }

    func testSpeechEndpointsAreLockedForClientIntegration() {
        XCTAssertEqual(P14SpeechContractManifest.taskID, "P14-T09")
        XCTAssertTrue(P14SpeechContractManifest.isLocked)
        XCTAssertEqual(P14SpeechContractManifest.statusWord, "模拟器完成-待真机")
        XCTAssertTrue(P14SpeechContractManifest.missingEndpoints.isEmpty)
        XCTAssertTrue(P14SpeechContractManifest.missingFixtureIDs.isEmpty)
        XCTAssertTrue(P14SpeechContractManifest.documentSaysServerAliasConfigured)
        XCTAssertFalse(P14SpeechContractManifest.bailianLiveReady)
        XCTAssertFalse(P14SpeechContractManifest.allowsClientTTSText)
        XCTAssertFalse(P14SpeechContractManifest.allowsResultInComposer)
        XCTAssertFalse(P14SpeechContractManifest.allowsAppleSpeech)
    }

    func testDocumentAndLiveSHAAreBothRecorded() {
        XCTAssertEqual(
            P14SpeechContractManifest.documentReviewedSHA256,
            "cdb52009a4ec253303a483f7a706d0439bc3fae8c728f146bbb7fa89fec71ae2"
        )
        XCTAssertEqual(
            P14SpeechContractManifest.liveOpenAPISHA256,
            "75f505f062674495cde0a3401ef82dcab3e278a4223119ca9e84b64863059bbd"
        )
        XCTAssertTrue(P14SpeechContractManifest.presentPaths.contains("POST /api/v1/transcribe"))
        XCTAssertTrue(P14SpeechContractManifest.presentPaths.contains("POST /api/v1/synthesize"))
    }

    func testSpecConstraintsStayAlignedWithLiveSchema() {
        XCTAssertEqual(P14SpeechContractManifest.specTranscribeMultipartFields, ["client_id", "audio"])
        XCTAssertEqual(
            P14SpeechContractManifest.specSynthesizeRequestKeys,
            ["client_id", "message_id", "voice_profile"]
        )
        XCTAssertEqual(P14SpeechContractManifest.specVoiceProfileValues, ["default"])
        XCTAssertTrue(P14SpeechContractManifest.allowedAudioMIMETypes.contains("audio/mp4"))
        XCTAssertEqual(P14SpeechContractManifest.specASRDailyLimit, 60)
        XCTAssertEqual(P14SpeechContractManifest.specTTSDailyLimit, 20)
        XCTAssertFalse(P14SpeechContractManifest.specSynthesizeRequestKeys.contains("text"))
    }
}
