import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class ChatViewModel {
    private(set) var messages: [ChatMessage] = []
    private(set) var generationState: ChatGenerationState = .idle
    private(set) var usesStubProvider = false
    private(set) var composerMode: ChatComposerMode = .text
    private(set) var voicePhase: VoiceComposerPhase = .idle
    private(set) var voiceStatusMessage: String?
    private(set) var isTTSPlaying = false
    private(set) var showsMicrophonePermissionPrompt = false
    private(set) var isVoiceQuotaBlocked = false
    var draftText = ""

    var blocksChatChrome: Bool {
        VoiceComposerPresentation.blocksChrome(voicePhase)
    }

    var canSubmit: Bool {
        ChatOutboundRules.canAcceptSubmission(messages: messages)
    }

    var isGenerating: Bool {
        if case .generating = generationState {
            return true
        }
        return false
    }

    var queueIsFull: Bool {
        !canSubmit && messages.contains { message in
            message.role == .user && (message.status == .queued || message.status == .sending)
        }
    }

    private(set) var hiddenMemoryIDs: Set<UUID> = []

    var timelineItems: [ChatTimelineItem] {
        ChatTimelineRules.timelineItems(
            from: MemoryCitationRules.strippingHidden(from: messages, hiddenMemoryIDs: hiddenMemoryIDs),
            now: now()
        )
    }

    private let chatService: any ChatServiceProtocol
    private let speechService: (any SpeechServiceProtocol)?
    private let messagesService: (any MessagesServiceProtocol)?
    private let extractService: (any ExtractServiceProtocol)?
    private let extractClientIDs: ExtractClientIDStore?
    private let historyCache: ChatHistoryCache
    private let localStore: LocalStore
    private let syncCoordinator: SyncCoordinator?
    private let accountUserID: UUID
    private let makeContext: () -> ChatSendContext
    private let onPatch: ((SessionPatch) -> Void)?
    private let now: () -> Date
    private let recorder = VoiceRecorder()
    private let player = TTSPlayer()
    private let audioSession = AudioSessionCoordinator()
    private var currentTranscribeClientID: UUID?
    private var synthesizeClientIDs: [UUID: UUID] = [:]
    private var lastWillCancel = false
    private var transcribeTask: Task<Void, Never>?
    private var voiceHoldGeneration = 0
    private var startedHoldGeneration: Int?
    private var ttsPlaybackRetryUsed = false

    private var sendPumpTask: Task<Void, Never>?
    private var nextCursor: String?
    private var historySnapshotAt: Date?

    init(
        chatService: any ChatServiceProtocol,
        historyCache: ChatHistoryCache,
        localStore: LocalStore,
        accountUserID: UUID,
        speechService: (any SpeechServiceProtocol)? = nil,
        messagesService: (any MessagesServiceProtocol)? = nil,
        extractService: (any ExtractServiceProtocol)? = nil,
        extractClientIDs: ExtractClientIDStore? = nil,
        syncCoordinator: SyncCoordinator? = nil,
        makeContext: @escaping () -> ChatSendContext = { ChatSendContext.make(weather: nil) },
        onPatch: ((SessionPatch) -> Void)? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.chatService = chatService
        self.speechService = speechService
        self.messagesService = messagesService
        self.extractService = extractService
        self.extractClientIDs = extractClientIDs
        self.historyCache = historyCache
        self.localStore = localStore
        self.syncCoordinator = syncCoordinator
        self.accountUserID = accountUserID
        self.makeContext = makeContext
        self.onPatch = onPatch
        self.now = now
        audioSession.onInterrupt = { [weak self] in
            self?.handleAudioInterruption()
        }
        audioSession.start()
    }

    func restore() async throws {
        await refreshHiddenMemoryIDs()
        let cached = try await historyCache.loadCachedMessages(accountUserID: accountUserID)
        messages = ChatOutboundRules.normalizeInterruptedOutbound(cached)
        if messages != cached {
            try await historyCache.persistMessages(messages, accountUserID: accountUserID)
        }
        await refreshHistoryFromServer()
        scheduleSendPump()
    }

    func submitDraft() async throws {
        let text = draftText
        draftText = ""
        try await submit(text: text, source: .text)
    }

    func submit(text: String, source: ChatMessage.Source = .text) async throws {
        let content = try ChatOutboundRules.validateContent(text)
        guard canSubmit else {
            throw AppError.invalidInput
        }

        let clientMessageID = UUID()
        let createdAt = now()
        let outbound = ChatOutboundRules.makeOutboundUserMessage(
            clientMessageID: clientMessageID,
            content: content,
            createdAt: createdAt,
            source: source
        )

        messages = ChatHistoryRules.presentableMessages(from: messages + [outbound])
        try await historyCache.persistMessages(messages, accountUserID: accountUserID)
        scheduleSendPump()
    }

    func retry(clientMessageID: UUID) async throws {
        guard let index = messages.firstIndex(where: { $0.clientID == clientMessageID && $0.role == .user }) else {
            throw AppError.notFound
        }

        let current = messages[index]
        guard current.status == .failed else {
            throw AppError.invalidInput
        }

        messages[index] = current.with(status: .queued)
        messages = ChatHistoryRules.presentableMessages(from: messages)
        try await historyCache.persistMessages(messages, accountUserID: accountUserID)
        scheduleSendPump()
    }

    func cancelQueued(clientMessageID: UUID) async throws {
        guard let message = messages.first(where: { $0.clientID == clientMessageID && $0.role == .user }) else {
            throw AppError.notFound
        }
        guard message.status == .queued else {
            throw AppError.invalidInput
        }

        messages.removeAll { $0.clientID == clientMessageID && $0.role == .user }
        messages = ChatHistoryRules.presentableMessages(from: messages)
        try await historyCache.persistMessages(messages, accountUserID: accountUserID)
        try await localStore.deletePendingOperation(id: message.id, accountUserID: accountUserID)
    }

    func setComposerMode(_ mode: ChatComposerMode) {
        guard !voicePhase.isRecording else { return }
        if mode == .voice, isVoiceQuotaBlocked {
            voiceStatusMessage = ErrorCopy.ttsQuotaExceeded
            return
        }
        composerMode = mode
        showsMicrophonePermissionPrompt = false
        if voicePhase.isProcessing {
            return
        }
        if voiceStatusMessage == String(localized: "按住说话，松开发送") {
            voiceStatusMessage = nil
        }
    }

    func markVoiceHoldStarted() {
        startedHoldGeneration = voiceHoldGeneration
    }

    func handleVoiceTap() {
        voiceHoldGeneration += 1
        recorder.cancel()
        currentTranscribeClientID = nil
        lastWillCancel = false
        voicePhase = .idle
        voiceStatusMessage = String(localized: "按住说话，松开发送")
    }

    func cancelVoiceProcessing() {
        invalidateVoiceHold()
        transcribeTask?.cancel()
        transcribeTask = nil
        recorder.cancel()
        currentTranscribeClientID = nil
        lastWillCancel = false
        voicePhase = .idle
        voiceStatusMessage = nil
    }

    func dismissMicrophonePermissionPrompt() {
        showsMicrophonePermissionPrompt = false
    }

    func openSystemSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }

    func beginVoiceHold() async {
        guard speechService != nil else { return }
        guard !voicePhase.isRecording, !voicePhase.isProcessing else { return }

        if isVoiceQuotaBlocked {
            composerMode = .text
            voiceStatusMessage = ErrorCopy.ttsQuotaExceeded
            return
        }

        guard let generation = startedHoldGeneration else { return }
        player.stop()
        isTTSPlaying = false
        voiceStatusMessage = nil
        showsMicrophonePermissionPrompt = false

        if MicrophonePermission.isDenied {
            voicePhase = .idle
            showsMicrophonePermissionPrompt = true
            return
        }

        if !MicrophonePermission.isGranted {
            voicePhase = .requestingPermission
            let granted = await MicrophonePermission.request()
            guard granted else {
                if generation == voiceHoldGeneration {
                    voicePhase = .idle
                    showsMicrophonePermissionPrompt = true
                }
                return
            }
        }

        guard generation == voiceHoldGeneration else { return }

        do {
            try recorder.start()
            currentTranscribeClientID = UUID()
            lastWillCancel = false
            voicePhase = .recording(duration: 0, willCancel: false)
            VoiceHaptics.light()
        } catch {
            recorder.cancel()
            voicePhase = .idle
            voiceStatusMessage = ErrorCopy.app(.invalidInput).message
        }
    }

    func updateVoiceHold(verticalTranslation: CGFloat, duration: TimeInterval) {
        guard case .recording = voicePhase else { return }
        let willCancel = VoiceRules.willCancel(verticalTranslation: verticalTranslation)
        if willCancel != lastWillCancel {
            VoiceHaptics.light()
            lastWillCancel = willCancel
        }
        voicePhase = .recording(duration: duration, willCancel: willCancel)
        if VoiceRules.shouldAutoSend(duration: duration) {
            Task { await finishVoiceHold(cancelled: false, duration: duration) }
        }
    }

    func finishVoiceHold(cancelled: Bool, duration: TimeInterval) async {
        guard case .recording = voicePhase else { return }
        invalidateVoiceHold()
        lastWillCancel = false

        if cancelled || VoiceRules.shouldDiscard(duration: duration) {
            recorder.cancel()
            currentTranscribeClientID = nil
            voicePhase = .idle
            voiceStatusMessage = cancelled ? nil : ErrorCopy.recordingTooShort
            return
        }

        await transcribeAndEnqueue()
    }

    func toggleTTS() async {
        if isTTSPlaying {
            stopTTS()
            return
        }

        guard let speechService else { return }
        guard let message = messages.last(where: { $0.role == .spirit && $0.status == .generated }) else {
            voiceStatusMessage = ErrorCopy.app(.notFound).message
            return
        }

        recorder.cancel()
        if case .recording = voicePhase {
            currentTranscribeClientID = nil
            voicePhase = .idle
        }

        let clientID = synthesizeClientIDs[message.id] ?? UUID()
        synthesizeClientIDs[message.id] = clientID
        ttsPlaybackRetryUsed = false
        await playSynthesized(clientID: clientID, messageID: message.id)
    }

    func stopTTS() {
        player.stop()
        isTTSPlaying = false
    }

    private func playSynthesized(clientID: UUID, messageID: UUID) async {
        guard let speechService else { return }
        do {
            let result = try await speechService.synthesize(clientID: clientID, messageID: messageID)
            KelinLog.api.info("synthesize_ok cache_hit=\(result.cacheHit) duration_ms=\(result.durationMs)")
            onPatch?(result.patch)
            if VoiceRules.isPlaybackExpired(result.expiresAt, now: now()) {
                await retryTTSPlayback(clientID: clientID, messageID: messageID)
                return
            }
            player.play(url: result.playbackURL) { [weak self] in
                Task { await self?.retryTTSPlayback(clientID: clientID, messageID: messageID) }
            }
            isTTSPlaying = true
            voiceStatusMessage = nil
        } catch let error as AppError {
            isTTSPlaying = false
            voiceStatusMessage = ErrorCopy.app(error).message
        } catch {
            isTTSPlaying = false
            voiceStatusMessage = ErrorCopy.app(.unknown(requestID: "")).message
        }
    }

    private func retryTTSPlayback(clientID: UUID, messageID: UUID) async {
        guard !ttsPlaybackRetryUsed else {
            stopTTS()
            voiceStatusMessage = ErrorCopy.app(.notFound).message
            return
        }
        ttsPlaybackRetryUsed = true
        await playSynthesized(clientID: clientID, messageID: messageID)
    }

    func handleAudioInterruption() {
        handleSceneBackground()
    }

    func handleSceneBackground() {
        let shouldClearStatus = voicePhase.isRecording || voicePhase.isProcessing
        transcribeTask?.cancel()
        transcribeTask = nil
        recorder.cancel()
        stopTTS()
        VoiceTempCleanup.purgeOrphans()
        audioSession.deactivate()
        currentTranscribeClientID = nil
        lastWillCancel = false
        invalidateVoiceHold()
        voicePhase = .idle
        if shouldClearStatus {
            voiceStatusMessage = nil
        }
    }

    private func invalidateVoiceHold() {
        voiceHoldGeneration += 1
        startedHoldGeneration = nil
    }

    private func transcribeAndEnqueue() async {
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performTranscribe()
        }
        transcribeTask = task
        await task.value
        if transcribeTask == task {
            transcribeTask = nil
        }
    }

    private func performTranscribe() async {
        guard let speechService else {
            recorder.cancel()
            voicePhase = .idle
            return
        }

        let clientID = currentTranscribeClientID ?? UUID()
        currentTranscribeClientID = clientID
        voicePhase = .uploading
        voiceStatusMessage = nil

        let clip: VoiceClip
        do {
            clip = try recorder.stop()
        } catch {
            recorder.cancel()
            voicePhase = .idle
            voiceStatusMessage = ErrorCopy.app(.invalidInput).message
            return
        }

        if clip.data.count > VoiceRules.maxAudioBytes {
            voicePhase = .idle
            voiceStatusMessage = ErrorCopy.app(.invalidInput).message
            return
        }

        guard !Task.isCancelled, currentTranscribeClientID == clientID else {
            return
        }

        voicePhase = .transcribing
        do {
            let result = try await speechService.transcribe(clientID: clientID, clip: clip)
            guard !Task.isCancelled, currentTranscribeClientID == clientID else {
                return
            }
            onPatch?(result.patch)
            currentTranscribeClientID = nil
            voicePhase = .idle
            voiceStatusMessage = nil
            try await submit(text: result.text, source: .voice)
        } catch is CancellationError {
            guard currentTranscribeClientID == clientID else { return }
            applyVoiceFailure(.cancelled)
        } catch let error as AppError {
            guard currentTranscribeClientID == clientID else { return }
            applyVoiceFailure(error)
        } catch {
            guard currentTranscribeClientID == clientID else { return }
            if Task.isCancelled {
                applyVoiceFailure(.cancelled)
            } else {
                applyVoiceFailure(.unknown(requestID: ""))
            }
        }
    }

    private func applyVoiceFailure(_ error: AppError) {
        voicePhase = .idle
        currentTranscribeClientID = nil
        switch VoiceComposerPresentation.outcome(for: error) {
        case .silent:
            voiceStatusMessage = nil
        case let .status(message):
            voiceStatusMessage = message
        case let .switchToText(message):
            isVoiceQuotaBlocked = true
            composerMode = .text
            voiceStatusMessage = message
        }
    }

    private func scheduleSendPump() {
        guard sendPumpTask == nil else {
            return
        }

        sendPumpTask = Task { @MainActor [weak self] in
            await self?.runSendPump()
        }
    }

    private func runSendPump() async {
        defer { sendPumpTask = nil }

        if ChatOutboundRules.hasInFlight(messages: messages) {
            messages = ChatOutboundRules.normalizeInterruptedOutbound(messages)
            try? await historyCache.persistMessages(messages, accountUserID: accountUserID)
        }

        while !Task.isCancelled {
            guard let next = ChatOutboundRules.nextSendableMessage(in: messages) else {
                generationState = .idle
                return
            }

            await markMessage(clientID: next.clientID, status: .sending)
            generationState = .generating(clientMessageID: next.clientID)

            let context = makeContext()
            let payload = ChatSendPayload(
                messageID: next.id,
                clientMessageID: next.clientID,
                content: next.content,
                context: context
            )

            do {
                let result = try await chatService.sendMessage(
                    clientMessageID: next.clientID,
                    content: next.content,
                    context: context,
                    source: next.source
                )
                usesStubProvider = result.usesStubProvider
                KelinLog.api.info(
                    "chat_turn source=\(result.usesStubProvider ? "stub" : "provider") extract=\(result.shouldExtract)"
                )
                onPatch?(result.patch)
                await applyTurnResult(result, forClientMessageID: next.clientID)
                if result.shouldExtract {
                    await runExtractIfNeeded(windowID: result.conversationWindowID)
                }
            } catch let error as AppError where error == .networkUnavailable {
                await markOfflineQueued(payload: payload, createdAt: next.createdAt)
                generationState = .idle
                return
            } catch is CancellationError {
                await markMessage(clientID: next.clientID, status: .queued)
                generationState = .idle
                return
            } catch {
                await markMessage(clientID: next.clientID, status: .failed)
                generationState = .idle
                continue
            }
        }
    }

    private func applyTurnResult(_ result: ChatTurnResult, forClientMessageID clientMessageID: UUID) async {
        guard let index = outboundIndex(for: clientMessageID) else {
            return
        }

        let previousID = messages[index].id
        let accepted = messages[index].with(
            id: result.userMessage.id,
            status: .accepted
        )
        messages[index] = accepted
        messages = ChatHistoryRules.presentableMessages(from: messages + [result.spiritMessage])
        generationState = .idle

        do {
            if previousID != accepted.id {
                try await localStore.deleteMessage(id: previousID, accountUserID: accountUserID)
            }
            try await historyCache.persistMessages(messages, accountUserID: accountUserID)
            try await localStore.deletePendingOperation(id: accepted.id, accountUserID: accountUserID)
            try await localStore.deletePendingOperation(id: previousID, accountUserID: accountUserID)
        } catch {
            return
        }
    }

    private func outboundIndex(for clientMessageID: UUID) -> Int? {
        if let sending = messages.firstIndex(where: {
            $0.clientID == clientMessageID && $0.role == .user && ($0.status == .sending || $0.status == .queued)
        }) {
            return sending
        }
        return messages.firstIndex(where: { $0.clientID == clientMessageID && $0.role == .user })
    }

    private func markOfflineQueued(payload: ChatSendPayload, createdAt: Date) async {
        await markMessage(clientID: payload.clientMessageID, status: .queued)

        do {
            let pending = try ChatOutboundRules.makePendingOperation(
                accountUserID: accountUserID,
                payload: payload,
                createdAt: createdAt
            )
            try await localStore.upsertPendingOperation(pending)
            try await syncCoordinator?.enqueue(pending)
        } catch {
            return
        }
    }

    private func refreshHistoryFromServer() async {
        guard let messagesService else {
            return
        }

        do {
            let page = try await messagesService.fetchMessages(cursor: nil, limit: 30)
            await applyRemotePage(page)
        } catch let error as AppError {
            KelinLog.api.error("messages_refresh_failed error_code=\(error.diagnosticCode)")
        } catch {
            KelinLog.api.error("messages_refresh_failed error_code=UNKNOWN")
        }
    }

    private func applyRemotePage(_ page: MessagesPage) async {
        nextCursor = page.nextCursor
        historySnapshotAt = page.snapshotAt
        messages = historyCache.mergeRemotePage(into: messages, page: page)
        try? await historyCache.persistMessages(messages, accountUserID: accountUserID)
        await refreshHiddenMemoryIDs()
    }

    func refreshHiddenMemoryIDs() async {
        do {
            let active = try await localStore.fetchActiveMemories(accountUserID: accountUserID)
            let tombstoned = try await localStore.fetchTombstonedMemories(accountUserID: accountUserID)
            let summaries = active.compactMap { try? MemoryCodec.decode($0.payloadData) }
            hiddenMemoryIDs = MemoryCacheRules.hiddenIDs(
                active: summaries,
                tombstones: tombstoned.map { MemoryTombstone(id: $0.id, deletedAt: $0.updatedAt) }
            ).union(Set(tombstoned.map(\.id)))
        } catch {
            return
        }
    }

    private func runExtractIfNeeded(windowID: UUID) async {
        guard let extractService, let extractClientIDs else {
            return
        }

        do {
            let clientID = try await extractClientIDs.clientID(for: windowID, accountUserID: accountUserID)
            let result = try await extractService.extract(
                clientID: clientID,
                conversationWindowID: windowID
            )
            KelinLog.api.info("extract_ok status=\(result.status.rawValue)")
            if result.status == .extracted {
                onPatch?(result.patch)
            }
        } catch let error as AppError {
            KelinLog.api.error("extract_failed error_code=\(error.diagnosticCode)")
        } catch {
            KelinLog.api.error("extract_failed error_code=UNKNOWN")
        }
    }

    private func markMessage(clientID: UUID, status: ChatMessage.Status) async {
        guard let index = messages.firstIndex(where: { $0.clientID == clientID && $0.role == .user }) else {
            return
        }

        messages[index] = messages[index].with(status: status)
        messages = ChatHistoryRules.presentableMessages(from: messages)

        do {
            try await historyCache.persistMessages(messages, accountUserID: accountUserID)
        } catch {
            return
        }
    }
}
