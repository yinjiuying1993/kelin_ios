import AVFoundation
import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class VoiceRecorder {
    private var recorder: AVAudioRecorder?
    private var fileURL: URL?

    func start() throws {
        cancel()
        VoiceTempCleanup.purgeOrphans()
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
        try session.setActive(true, options: [])

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(VoiceTempCleanup.filePrefix)\(UUID().uuidString.lowercased()).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        VoiceTempCleanup.applyFileProtection(at: url)
        guard recorder.record() else {
            throw AppError.invalidInput
        }
        self.recorder = recorder
        fileURL = url
    }

    func stop() throws -> VoiceClip {
        let duration = recorder?.currentTime ?? 0
        recorder?.stop()
        defer { deleteTemporaryFile() }
        guard let fileURL else {
            throw AppError.invalidInput
        }
        let data = try Data(contentsOf: fileURL)
        return VoiceClip(data: data, mimeType: "audio/mp4", duration: duration)
    }

    func cancel() {
        recorder?.stop()
        deleteTemporaryFile()
    }

    private func deleteTemporaryFile() {
        if let fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        fileURL = nil
        recorder = nil
    }
}

@MainActor
final class TTSPlayer {
    private var player: AVPlayer?
    private var failureObserver: NSObjectProtocol?
    private var didReportFailure = false

    var isPlaying: Bool {
        player?.timeControlStatus == .playing || player?.rate != 0
    }

    func play(url: URL, onFailed: (@MainActor () -> Void)? = nil) {
        stop()
        didReportFailure = false
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player
        failureObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.didReportFailure else { return }
                self.didReportFailure = true
                onFailed?()
            }
        }
        player.play()
    }

    func stop() {
        if let failureObserver {
            NotificationCenter.default.removeObserver(failureObserver)
            self.failureObserver = nil
        }
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
}

enum MicrophonePermission {
    static func request() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    static var isGranted: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    static var isDenied: Bool {
        AVAudioApplication.shared.recordPermission == .denied
    }
}

enum VoiceTempCleanup {
    static let filePrefix = "kelin-asr-"

    static func purgeOrphans(in directory: URL = FileManager.default.temporaryDirectory) {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []
        for url in files where url.lastPathComponent.hasPrefix(filePrefix) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    static func applyFileProtection(at url: URL) {
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
    }
}

enum AudioSessionRules {
    enum Event: Equatable, Sendable {
        case cancelVoiceAndTTS
    }

    static func event(fromUserInfo userInfo: [AnyHashable: Any]?) -> Event? {
        guard let raw = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw),
              type == .began
        else {
            return nil
        }
        return .cancelVoiceAndTTS
    }
}

@MainActor
final class AudioSessionCoordinator {
    var onInterrupt: (() -> Void)?
    private var observers: [NSObjectProtocol] = []

    func start() {
        stop()
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()
        observers.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: session,
                queue: .main
            ) { [weak self] notification in
                guard AudioSessionRules.event(fromUserInfo: notification.userInfo) == .cancelVoiceAndTTS else {
                    return
                }
                Task { @MainActor in
                    self?.onInterrupt?()
                }
            }
        )
    }

    func stop() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

enum VoiceHaptics {
    @MainActor
    static func light() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
