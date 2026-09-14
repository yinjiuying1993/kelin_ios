import Foundation

enum ChatComposerMode: Equatable, Sendable {
    case text
    case voice
}

enum VoiceComposerPhase: Equatable, Sendable {
    case idle
    case requestingPermission
    case recording(duration: TimeInterval, willCancel: Bool)
    case uploading
    case transcribing

    var isRecording: Bool {
        if case .recording = self {
            return true
        }
        return false
    }

    var isProcessing: Bool {
        self == .uploading || self == .transcribing
    }

    var willCancel: Bool {
        if case let .recording(_, willCancel) = self {
            return willCancel
        }
        return false
    }

    var recordingDuration: TimeInterval {
        if case let .recording(duration, _) = self {
            return duration
        }
        return 0
    }
}

enum VoiceFailureOutcome: Equatable, Sendable {
    case silent
    case status(String)
    case switchToText(String)
}

enum VoiceComposerPresentation {
    static func holdLabel(isRecording: Bool, willCancel: Bool) -> String {
        if !isRecording {
            return String(localized: "按住说话")
        }
        return willCancel
            ? String(localized: "松开 取消")
            : String(localized: "松开 发送")
    }

    static func hintLabel(willCancel: Bool) -> String {
        willCancel
            ? String(localized: "松开取消")
            : String(localized: "上滑取消录音")
    }

    static func processingLabel(_ phase: VoiceComposerPhase) -> String? {
        switch phase {
        case .uploading:
            String(localized: "它在听")
        case .transcribing:
            String(localized: "它在辨认你说的话")
        default:
            nil
        }
    }

    static func outcome(for error: AppError) -> VoiceFailureOutcome {
        switch error {
        case .cancelled:
            .silent
        case .asrEmptyResult:
            .status(ErrorCopy.asrEmptyResult)
        case let .quotaExceeded(kind, _) where kind == .asr:
            .switchToText(ErrorCopy.ttsQuotaExceeded)
        default:
            .status(ErrorCopy.app(error).message)
        }
    }

    static func blocksChrome(_ phase: VoiceComposerPhase) -> Bool {
        phase.isRecording
    }
}

enum VoiceRules {
    static let minHoldSeconds = P14SpeechContractManifest.specMinHoldSeconds
    static let maxHoldSeconds = TimeInterval(P14SpeechContractManifest.specMaxAudioSeconds)
    static let tapMaxSeconds: TimeInterval = 0.2
    static let cancelDistancePoints = CGFloat(P14SpeechContractManifest.specCancelDistancePoints)
    static let maxAudioBytes = P14SpeechContractManifest.specMaxAudioBytes
    static let playbackHostToRewrite = "kelin.invalid"

    static func willCancel(verticalTranslation: CGFloat) -> Bool {
        verticalTranslation <= -cancelDistancePoints
    }

    static func shouldDiscard(duration: TimeInterval) -> Bool {
        duration < minHoldSeconds
    }

    static func shouldAutoSend(duration: TimeInterval) -> Bool {
        duration >= maxHoldSeconds
    }

    static func isTap(duration: TimeInterval) -> Bool {
        duration < tapMaxSeconds
    }

    static func formattedHoldDuration(_ duration: TimeInterval) -> String {
        let seconds = min(max(Int(duration), 0), Int(maxHoldSeconds))
        return "0:\(String(format: "%02d", seconds))"
    }

    static func isPlaybackExpired(_ expiresAt: Date, now: Date) -> Bool {
        expiresAt <= now
    }

    static func rewrittenPlaybackURL(_ audioURL: URL, apiBaseURL: URL) -> URL {
        guard var components = URLComponents(url: audioURL, resolvingAgainstBaseURL: false) else {
            return audioURL
        }
        guard components.host == playbackHostToRewrite else {
            return audioURL
        }

        components.scheme = apiBaseURL.scheme
        components.host = apiBaseURL.host
        components.port = apiBaseURL.port
        return components.url ?? audioURL
    }
}
