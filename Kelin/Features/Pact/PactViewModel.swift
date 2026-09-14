import Foundation

@MainActor
@Observable
final class PactViewModel {
    private(set) var phase: PactScreenPhase
    private(set) var selectedTheme: PactTheme
    private(set) var dayIndex: Int
    private(set) var completenessPercent: Int
    private(set) var questions: [PactQuestionFixture]
    private(set) var statusMessage: String?
    private(set) var isBusy = false
    var draftAnswer = ""
    var showsSkipConfirm = false
    var showsWeekRecap = false

    let spiritName: String
    let isOffline: Bool
    let usesRemotePactAPI: Bool

    private var pact: PactSummary?
    private var sessionStatus: String?
    private var sessionID: UUID?
    private var sessionDate: String?
    private var rowVersion: Int?
    private let pactService: (any PactServiceProtocol)?
    private let queueStore: PactAnswerQueueStore?
    private let clientIDs: PactClientIDStore?
    private let accountUserID: UUID?
    private let notesMemoryID: UUID?
    private let serverTime: Date?
    private let timeZoneIdentifier: String?
    private let onPatch: ((SessionPatch) -> Void)?

    var currentQuestion: PactQuestionFixture? {
        switch phase {
        case let .answering(index), let .reviewing(index):
            questions.indices.contains(index) ? questions[index] : nil
        default:
            nil
        }
    }

    var canSubmitAnswer: Bool {
        !draftAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isBusy
    }

    var commitTitle: String {
        PactPresentationRules.commitTitle(for: selectedTheme)
    }

    init(
        spiritName: String,
        isOffline: Bool,
        activePact: PactSummary? = nil,
        usesRemotePactAPI: Bool = false,
        questions: [PactQuestionFixture] = PactDraftFixtures.questions,
        pactService: (any PactServiceProtocol)? = nil,
        queueStore: PactAnswerQueueStore? = nil,
        clientIDs: PactClientIDStore? = nil,
        accountUserID: UUID? = nil,
        notesMemoryID: UUID? = nil,
        serverTime: Date? = nil,
        timeZoneIdentifier: String? = nil,
        onPatch: ((SessionPatch) -> Void)? = nil
    ) {
        self.spiritName = spiritName
        self.isOffline = isOffline
        self.usesRemotePactAPI = usesRemotePactAPI
        self.questions = usesRemotePactAPI ? questions : (questions.isEmpty ? PactDraftFixtures.questions : questions)
        self.pactService = pactService
        self.queueStore = queueStore
        self.clientIDs = clientIDs
        self.accountUserID = accountUserID
        self.notesMemoryID = notesMemoryID
        self.serverTime = serverTime
        self.timeZoneIdentifier = timeZoneIdentifier
        self.onPatch = onPatch
        pact = activePact
        selectedTheme = activePact.flatMap { PactTheme(rawValue: $0.theme) } ?? .interview
        if usesRemotePactAPI {
            completenessPercent = activePact?.completeness ?? 0
            dayIndex = 1
        } else {
            dayIndex = PactDraftFixtures.sampleDayIndex
            completenessPercent = activePact?.completeness ?? PactDraftFixtures.sampleCompletenessPercent
        }
        phase = PactCacheRules.resolvePhase(pact: activePact, sessionStatus: nil)
    }

    func selectTheme(_ theme: PactTheme) {
        guard phase == .unsigned else { return }
        selectedTheme = theme
    }

    func commitUnsigned() {
        guard phase == .unsigned, !isBusy else { return }
        if usesRemotePactAPI {
            Task { await createRemotePact() }
            return
        }
        phase = .active
    }

    var latestImprovement: String? {
        questions.reversed().first(where: { !$0.improvement.isEmpty })?.improvement
    }

    var tonightPrompt: String? {
        questions.first?.prompt
    }

    func startToday() {
        guard phase == .active, !isBusy else { return }
        if usesRemotePactAPI {
            Task { await openRemoteSession() }
            return
        }
        guard !questions.isEmpty else { return }
        draftAnswer = ""
        phase = .answering(index: 0)
    }

    func submitAnswer() {
        guard case let .answering(index) = phase, canSubmitAnswer else { return }
        if usesRemotePactAPI {
            Task { await submitRemoteAnswer(index: index) }
            return
        }
        draftAnswer = ""
        phase = .reviewing(index: index)
    }

    func continueAfterReview() {
        guard case let .reviewing(index) = phase else { return }
        let next = index + 1
        if next < questions.count {
            phase = .answering(index: next)
            return
        }
        if usesRemotePactAPI {
            applyServerPhase(sessionStatus: "answered")
        } else {
            phase = .todayCompleted
        }
    }

    func confirmSkipToday() {
        showsSkipConfirm = false
        guard phase == .active, !isBusy else { return }
        if usesRemotePactAPI {
            Task { await skipRemoteToday() }
            return
        }
        phase = .todayCompleted
    }

    func previewCompleted() {
        completenessPercent = PactDraftFixtures.sampleCompletedPercent
        phase = .completed
    }

    func previewActive() {
        selectedTheme = .interview
        phase = .active
    }

    func restoreQueueIfNeeded() async {
        guard usesRemotePactAPI, let queueStore, let accountUserID else { return }
        do {
            let state = try await queueStore.load(accountUserID: accountUserID)
            sessionID = state.sessionID
            sessionDate = state.sessionDate
            sessionStatus = state.sessionStatus
            rowVersion = state.rowVersion
            if let dayIndex = state.dayIndex {
                self.dayIndex = dayIndex
            }
            applyServerPhase(sessionStatus: state.sessionStatus)
            try await replayQueue()
        } catch {
            statusMessage = ErrorCopy.app(.decoding).message
        }
    }

    private func createRemotePact() async {
        guard let pactService else { return }
        if selectedTheme == .notes, notesMemoryID == nil {
            statusMessage = String(localized: "先投喂一段知识，才能立下笔记契约")
            return
        }

        await runRemote {
            let clientID = try await self.stableID(PactClientIDStore.createKey(pactTheme: self.selectedTheme.rawValue))
            let mutation = try await pactService.createPact(
                theme: self.selectedTheme.rawValue,
                title: PactPresentationRules.themeTitle(self.selectedTheme),
                notesMemoryID: self.selectedTheme == .notes ? self.notesMemoryID : nil,
                clientID: clientID
            )
            self.applyMutation(mutation, sessionStatus: nil)
        }
    }

    private func openRemoteSession() async {
        guard let pactService, let pact else { return }
        await runRemote {
            let day = self.currentServerDay()
            let clientID = try await self.stableID(PactClientIDStore.sessionKey(pactID: pact.id, day: day))
            let mutation = try await pactService.createSession(pactID: pact.id, clientID: clientID)
            if let session = mutation.session {
                self.sessionID = session.id
                self.sessionDate = session.date.isEmpty ? day : session.date
                self.sessionStatus = session.status
                self.rowVersion = session.rowVersion
                self.dayIndex = session.dayIndex ?? self.dayIndex
                if !session.questions.isEmpty {
                    self.questions = session.questions.enumerated().map { index, question in
                        PactQuestionFixture(
                            id: self.questions.indices.contains(index) ? self.questions[index].id : UUID(),
                            questionID: question.id,
                            prompt: question.text,
                            comment: "",
                            improvement: ""
                        )
                    }
                }
                try await self.persistQueueMeta()
            }
            self.applyMutation(mutation, sessionStatus: mutation.session?.status)
            self.draftAnswer = ""
            if self.phase == .active {
                self.phase = .answering(index: 0)
            }
        }
    }

    private func submitRemoteAnswer(index: Int) async {
        guard let pactService, let sessionID, let rowVersion else { return }
        let question = questions[index]
        let text = draftAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        await runRemote {
            let clientID = try await self.stableID(
                PactClientIDStore.answerKey(sessionID: sessionID, questionID: question.questionID)
            )
            let item = PactAnswerQueueItem(
                clientID: clientID,
                sessionID: sessionID,
                expectedSessionVersion: rowVersion,
                questionID: question.questionID,
                text: text,
                order: index
            )
            if let queueStore = self.queueStore, let accountUserID = self.accountUserID {
                try await queueStore.enqueue(item, accountUserID: accountUserID)
            }
            let mutation = try await pactService.submitAnswer(
                sessionID: sessionID,
                expectedSessionVersion: rowVersion,
                questionID: question.questionID,
                text: text,
                clientID: clientID
            )
            if let nextVersion = mutation.answer?.rowVersion {
                self.rowVersion = nextVersion
            }
            if let summary = mutation.answer?.feedbackSummary {
                self.questions[index].comment = summary
            }
            if let improvement = mutation.answer?.improvement {
                self.questions[index].improvement = improvement
            }
            if let queueStore = self.queueStore, let accountUserID = self.accountUserID {
                try await queueStore.remove(questionID: question.questionID, accountUserID: accountUserID)
            }
            self.draftAnswer = ""
            let nextStatus = mutation.answer?.finalized == true ? "answered" : self.sessionStatus
            self.applyMutation(mutation, sessionStatus: nextStatus)
            if mutation.answer?.finalized == true {
                self.phase = .reviewing(index: index)
            } else {
                self.phase = .reviewing(index: index)
            }
        }
    }

    private func skipRemoteToday() async {
        guard let pactService, let pact else { return }
        await runRemote {
            let day = self.sessionDate ?? self.currentServerDay()
            let clientID = try await self.stableID(PactClientIDStore.skipKey(pactID: pact.id, day: day))
            let mutation = try await pactService.skipToday(
                pactID: pact.id,
                sessionDate: day,
                clientID: clientID
            )
            self.sessionStatus = mutation.session?.status ?? "skipped"
            self.sessionDate = mutation.session?.date.isEmpty == false ? mutation.session?.date : day
            try await self.persistQueueMeta()
            self.applyMutation(mutation, sessionStatus: self.sessionStatus)
        }
    }

    private func replayQueue() async throws {
        guard let pactService, let queueStore, let accountUserID else { return }
        while let item = try await queueStore.next(accountUserID: accountUserID) {
            let mutation = try await pactService.submitAnswer(
                sessionID: item.sessionID,
                expectedSessionVersion: item.expectedSessionVersion,
                questionID: item.questionID,
                text: item.text,
                clientID: item.clientID
            )
            if let nextVersion = mutation.answer?.rowVersion {
                rowVersion = nextVersion
            }
            applyMutation(mutation, sessionStatus: mutation.answer?.finalized == true ? "answered" : sessionStatus)
            try await queueStore.remove(questionID: item.questionID, accountUserID: accountUserID)
        }
    }

    private func applyMutation(_ mutation: PactMutation, sessionStatus: String?) {
        if let pact = mutation.pact {
            self.pact = pact
            if let completeness = pact.completeness {
                completenessPercent = completeness
            }
            if let theme = PactTheme(rawValue: pact.theme) {
                selectedTheme = theme
            }
        }
        if let sessionStatus {
            self.sessionStatus = sessionStatus
        }
        onPatch?(mutation.patch)
        applyServerPhase(sessionStatus: self.sessionStatus)
        statusMessage = nil
    }

    private func applyServerPhase(sessionStatus: String?) {
        phase = PactCacheRules.resolvePhase(pact: pact, sessionStatus: sessionStatus)
    }

    private func currentServerDay() -> String {
        let timeZone: TimeZone
        if let timeZoneIdentifier, let parsed = TimeZone(identifier: timeZoneIdentifier) {
            timeZone = parsed
        } else {
            timeZone = PactCacheRules.shanghaiTimeZone()
        }
        return PactCacheRules.serverDay(from: serverTime ?? Date(), timeZone: timeZone)
    }

    private func stableID(_ key: String) async throws -> UUID {
        guard let clientIDs, let accountUserID else {
            return UUID()
        }
        return try await clientIDs.clientID(for: key, accountUserID: accountUserID)
    }

    private func persistQueueMeta() async throws {
        guard let queueStore, let accountUserID else { return }
        var state = try await queueStore.load(accountUserID: accountUserID)
        state.sessionID = sessionID
        state.sessionDate = sessionDate
        state.sessionStatus = sessionStatus
        state.rowVersion = rowVersion
        state.dayIndex = dayIndex
        try await queueStore.save(state, accountUserID: accountUserID)
    }

    private func runRemote(_ work: @escaping () async throws -> Void) async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await work()
        } catch let error as AppError {
            if error == .idempotencyInProgress {
                statusMessage = ErrorCopy.app(error).message
                return
            }
            statusMessage = pactMessage(for: error)
            KelinLog.api.error("pact_mutation error_code=\(error.diagnosticCode)")
        } catch {
            statusMessage = ErrorCopy.app(.unknown(requestID: "")).message
        }
    }

    private func pactMessage(for error: AppError) -> String {
        switch error {
        case .conflict:
            String(localized: "已有进行中的契约，或今天不能再开场")
        case .notFound:
            String(localized: "共学接口尚未开通，或题目不属于本场")
        case .invalidInput:
            String(localized: "请按题序作答，不要改日期")
        default:
            ErrorCopy.app(error).message
        }
    }
}
