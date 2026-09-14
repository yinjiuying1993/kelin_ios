import Foundation

enum FeedFoodPhase: Equatable, Sendable {
    case idle
    case feeding
    case warmed
}

enum FeedPromisePhase: Equatable, Sendable {
    case empty
    case editing
    case locked
}

struct FeedLocationDraft: Equatable, Sendable {
    var city: String
    var label: String
    var category: FeedLocationCategory?
}

@MainActor
@Observable
final class FeedViewModel {
    var knowledgeDraft = ""
    var selectedEmotion: FeedEmotion = .tired
    var promiseText = ""
    var promiseDate = Date().addingTimeInterval(3_600)
    var locationCity = ""
    var locationLabel = ""
    var locationCategory: FeedLocationCategory?
    var isShowingLocationSheet = false

    private(set) var foodPhase: FeedFoodPhase = .idle
    private(set) var promisePhase: FeedPromisePhase = .empty
    private(set) var foodState: FeedCardState = .idle
    private(set) var knowledgeState: FeedCardState = .idle
    private(set) var emotionState: FeedCardState = .idle
    private(set) var sightState: FeedCardState = .idle
    private(set) var promiseState: FeedCardState = .idle
    private(set) var statusMessage: String?
    private(set) var foodQuotaText: String
    private(set) var sightQuotaText: String
    private(set) var isOffline: Bool
    private(set) var hasPhotoPreview = false
    private(set) var locationDraft: FeedLocationDraft?
    private(set) var activePromiseID: UUID?

    private let feedService: any FeedServiceProtocol
    private let photoProcessor: PhotoProcessor
    private let sightUploader: SightUploader
    private let clientIDs: FeedClientIDStore?
    private let accountUserID: UUID?
    private let onPatch: ((SessionPatch) -> Void)?
    private var spiritVersion: Int
    private var processedPhoto: ProcessedSightPhoto?
    private var photoItemCleared = false

    init(
        quotas: [QuotaEntry],
        isOffline: Bool,
        spiritVersion: Int = 1,
        feedService: any FeedServiceProtocol = MockFeedService(),
        photoProcessor: PhotoProcessor = PhotoProcessor(),
        sightUploader: SightUploader = SightUploader(),
        clientIDs: FeedClientIDStore? = nil,
        accountUserID: UUID? = nil,
        activePromiseID: UUID? = nil,
        activePromiseText: String? = nil,
        activePromiseRemindAt: Date? = nil,
        onPatch: ((SessionPatch) -> Void)? = nil
    ) {
        self.foodQuotaText = FeedPresentationRules.foodQuotaText(from: quotas)
        self.sightQuotaText = FeedPresentationRules.quotaText(for: .sight, from: quotas, defaultLimit: 2)
        self.isOffline = isOffline
        self.spiritVersion = spiritVersion
        self.feedService = feedService
        self.photoProcessor = photoProcessor
        self.sightUploader = sightUploader
        self.clientIDs = clientIDs
        self.accountUserID = accountUserID
        self.activePromiseID = activePromiseID
        self.onPatch = onPatch
        if let activePromiseID {
            promisePhase = .locked
            promiseText = activePromiseText ?? ""
            if let activePromiseRemindAt {
                promiseDate = activePromiseRemindAt
            }
            self.activePromiseID = activePromiseID
        }
    }

    var knowledgeCountText: String {
        "\(knowledgeDraft.count)/\(FeedPresentationRules.knowledgeClosedRange.upperBound)"
    }

    var canSubmitKnowledge: Bool {
        (try? FeedPresentationRules.validateKnowledge(knowledgeDraft)) != nil
            && knowledgeState != .submitting
    }

    func restorePersistedPromise() async {
        guard let clientIDs, let accountUserID else { return }
        guard let stored = try? await clientIDs.load(accountUserID: accountUserID),
              let id = stored.activePromiseID
        else { return }
        activePromiseID = id
        promiseText = stored.activePromiseText ?? promiseText
        if let remindAt = stored.activePromiseRemindAt {
            promiseDate = remindAt
        }
        promisePhase = .locked
    }

    func applySnapshot(quotas: [QuotaEntry], isOffline: Bool, spiritVersion: Int? = nil) {
        foodQuotaText = FeedPresentationRules.foodQuotaText(from: quotas)
        sightQuotaText = FeedPresentationRules.quotaText(for: .sight, from: quotas, defaultLimit: 2)
        self.isOffline = isOffline
        if let spiritVersion {
            self.spiritVersion = spiritVersion
        }
    }

    func feedFood() {
        guard foodState != .submitting, foodPhase == .idle else { return }
        Task { await submitFood() }
    }

    func submitKnowledge() {
        Task { await sendKnowledge() }
    }

    func selectEmotion(_ emotion: FeedEmotion) {
        selectedEmotion = emotion
        Task { await sendEmotion() }
    }

    func beginPromise() {
        promisePhase = .editing
        statusMessage = nil
    }

    func lockPromise() {
        Task { await submitPromise() }
    }

    func cancelPromise() {
        Task { await sendCancelPromise() }
    }

    func completePromise() {
        Task { await sendCompletePromise() }
    }

    func setPhotoPreview(_ hasPreview: Bool) {
        hasPhotoPreview = hasPreview
        if !hasPreview {
            processedPhoto = nil
        }
    }

    func processPickedPhoto(_ data: Data?) async {
        guard let data else {
            clearPhotoPreview()
            return
        }
        do {
            processedPhoto = try await photoProcessor.process(data)
            hasPhotoPreview = true
            statusMessage = nil
        } catch {
            processedPhoto = nil
            hasPhotoPreview = false
            sightState = .failed
            statusMessage = ErrorCopy.app(.invalidInput).message
        }
    }

    func clearPhotoPreview() {
        hasPhotoPreview = false
        processedPhoto = nil
        photoItemCleared = true
    }

    func consumePhotoClearFlag() -> Bool {
        defer { photoItemCleared = false }
        return photoItemCleared
    }

    func confirmSight() {
        Task { await submitPhotoSight() }
    }

    func submitLocation() {
        Task { await sendLocation() }
    }

    private func submitFood() async {
        guard !isOffline else {
            foodState = .failed
            statusMessage = ErrorCopy.app(.networkUnavailable).message
            return
        }

        foodState = .submitting
        foodPhase = .feeding
        statusMessage = nil
        do {
            let clientID = try await stableID(FeedClientIDStore.foodKey)
            let mutation = try await feedService.createFood(clientID: clientID)
            apply(mutation)
            try await forget(FeedClientIDStore.foodKey)
            foodState = .success
            foodPhase = .warmed
            try? await Task.sleep(for: .seconds(1.2))
            if foodPhase == .warmed {
                foodPhase = .idle
                foodState = .idle
            }
        } catch {
            foodState = .failed
            foodPhase = .idle
            statusMessage = ErrorCopy.app(mapped(error)).message
        }
    }

    private func sendKnowledge() async {
        do {
            let text = try FeedPresentationRules.validateKnowledge(knowledgeDraft)
            guard !isOffline else {
                knowledgeState = .failed
                statusMessage = ErrorCopy.app(.networkUnavailable).message
                return
            }
            knowledgeState = .submitting
            let clientID = try await stableID(FeedClientIDStore.knowledgeKey)
            let mutation = try await feedService.createKnowledge(text: text, clientID: clientID)
            apply(mutation)
            try await forget(FeedClientIDStore.knowledgeKey)
            knowledgeDraft = ""
            knowledgeState = .success
            statusMessage = String(localized: "它记进书里了")
        } catch {
            knowledgeState = .failed
            statusMessage = ErrorCopy.app(mapped(error)).message
        }
    }

    private func sendEmotion() async {
        guard !isOffline else {
            emotionState = .failed
            statusMessage = ErrorCopy.app(.networkUnavailable).message
            return
        }
        emotionState = .submitting
        do {
            let clientID = try await stableID(FeedClientIDStore.emotionKey)
            let mutation = try await feedService.createEmotion(
                emotion: selectedEmotion.rawValue,
                note: nil,
                clientID: clientID
            )
            apply(mutation)
            try await forget(FeedClientIDStore.emotionKey)
            emotionState = .success
            statusMessage = nil
        } catch {
            emotionState = .failed
            statusMessage = ErrorCopy.app(mapped(error)).message
        }
    }

    private func submitPromise() async {
        do {
            let range = activePromiseID == nil
                ? FeedPresentationRules.promiseCreateClosedRange
                : FeedPresentationRules.promisePatchClosedRange
            let text = try FeedPresentationRules.validatePromiseText(promiseText, range: range)
            guard !isOffline else {
                promiseState = .failed
                statusMessage = ErrorCopy.app(.networkUnavailable).message
                return
            }

            promiseState = .submitting
            if let activePromiseID {
                let clientID = try await stableID(FeedClientIDStore.promisePatchKey)
                let mutation = try await feedService.patchPromise(
                    feedID: activePromiseID,
                    expectedVersion: spiritVersion,
                    text: text,
                    remindAt: promiseDate,
                    clientID: clientID
                )
                apply(mutation)
                try await forget(FeedClientIDStore.promisePatchKey)
                try await rememberPromise(id: activePromiseID, text: text, remindAt: promiseDate)
                FeedPromiseNotifier.replace(feedID: activePromiseID, remindAt: promiseDate)
            } else {
                let clientID = try await stableID(FeedClientIDStore.promiseCreateKey)
                let mutation = try await feedService.createPromise(
                    text: text,
                    remindAt: promiseDate,
                    clientID: clientID
                )
                apply(mutation)
                try await forget(FeedClientIDStore.promiseCreateKey)
                activePromiseID = mutation.resource.id
                try await rememberPromise(id: mutation.resource.id, text: text, remindAt: promiseDate)
                FeedPromiseNotifier.schedule(feedID: mutation.resource.id, remindAt: promiseDate)
            }
            promisePhase = .locked
            promiseState = .success
        } catch {
            promiseState = .failed
            statusMessage = ErrorCopy.app(mapped(error)).message
        }
    }

    private func sendCompletePromise() async {
        guard let activePromiseID else { return }
        guard !isOffline else {
            promiseState = .failed
            statusMessage = ErrorCopy.app(.networkUnavailable).message
            return
        }
        promiseState = .submitting
        do {
            let clientID = try await stableID(FeedClientIDStore.promiseCompleteKey)
            let mutation = try await feedService.completePromise(
                feedID: activePromiseID,
                expectedVersion: spiritVersion,
                clientID: clientID
            )
            apply(mutation)
            try await forget(FeedClientIDStore.promiseCompleteKey)
            try await clientIDs?.clearPromise(accountUserID: try accountID())
            FeedPromiseNotifier.remove(feedID: activePromiseID)
            self.activePromiseID = nil
            promiseText = ""
            promisePhase = .empty
            promiseState = .success
            statusMessage = nil
        } catch {
            promiseState = .failed
            statusMessage = ErrorCopy.app(mapped(error)).message
        }
    }

    private func sendCancelPromise() async {
        guard let activePromiseID else {
            promiseText = ""
            promisePhase = .empty
            statusMessage = nil
            return
        }
        guard !isOffline else {
            promiseState = .failed
            statusMessage = ErrorCopy.app(.networkUnavailable).message
            return
        }

        promiseState = .submitting
        do {
            let clientID = try await stableID(FeedClientIDStore.promiseCancelKey)
            let mutation = try await feedService.cancelPromise(
                feedID: activePromiseID,
                expectedVersion: spiritVersion,
                clientID: clientID
            )
            apply(mutation)
            try await forget(FeedClientIDStore.promiseCancelKey)
            try await clientIDs?.clearPromise(accountUserID: try accountID())
            FeedPromiseNotifier.remove(feedID: activePromiseID)
            self.activePromiseID = nil
            promiseText = ""
            promisePhase = .empty
            promiseState = .idle
            statusMessage = nil
        } catch {
            promiseState = .failed
            statusMessage = ErrorCopy.app(mapped(error)).message
        }
    }

    private func sendLocation() async {
        do {
            let location = try FeedPresentationRules.validateLocation(
                city: locationCity,
                label: locationLabel,
                category: locationCategory
            )
            guard !isOffline else {
                sightState = .failed
                statusMessage = ErrorCopy.app(.networkUnavailable).message
                return
            }
            sightState = .submitting
            let clientID = try await stableID(FeedClientIDStore.sightLocationKey)
            let mutation = try await feedService.createLocationSight(
                label: location.label,
                city: location.city,
                category: location.category,
                clientID: clientID
            )
            apply(mutation)
            try await forget(FeedClientIDStore.sightLocationKey)
            locationDraft = FeedLocationDraft(
                city: location.city,
                label: location.label,
                category: locationCategory
            )
            isShowingLocationSheet = false
            if mutation.resource.status == "rejected" {
                sightState = .failed
                statusMessage = ErrorCopy.sightRejected
            } else {
                sightState = .success
                statusMessage = nil
            }
        } catch {
            sightState = .failed
            statusMessage = ErrorCopy.app(mapped(error)).message
        }
    }

    private func submitPhotoSight() async {
        guard let processedPhoto else {
            sightState = .failed
            statusMessage = ErrorCopy.app(.invalidInput).message
            return
        }
        guard !isOffline else {
            sightState = .failed
            statusMessage = ErrorCopy.app(.networkUnavailable).message
            return
        }

        sightState = .submitting
        statusMessage = nil
        do {
            let feedClientID = try await stableID(FeedClientIDStore.sightPhotoFeedKey)
            let feed = try await feedService.createPhotoSight(clientID: feedClientID)
            apply(feed)

            let uploadClientID = try await stableID(FeedClientIDStore.sightPhotoUploadKey)
            let ticket = try await requestUploadTicket(
                feedID: feed.resource.id,
                photo: processedPhoto,
                clientID: uploadClientID
            )
            try await sightUploader.put(ticket: ticket, jpeg: processedPhoto.jpeg)
            try await forget(FeedClientIDStore.sightPhotoUploadKey)

            let moderateClientID = try await stableID(FeedClientIDStore.sightPhotoModerateKey)
            let moderated = try await feedService.moderateSight(
                feedID: feed.resource.id,
                uploadSessionID: ticket.uploadSessionID,
                clientID: moderateClientID
            )
            apply(moderated)
            try await forget(FeedClientIDStore.sightPhotoFeedKey)
            try await forget(FeedClientIDStore.sightPhotoModerateKey)
            clearPhotoPreview()
            if moderated.resource.status == "rejected" {
                sightState = .failed
                statusMessage = ErrorCopy.sightRejected
            } else {
                sightState = .success
                statusMessage = nil
            }
        } catch {
            sightState = .failed
            statusMessage = photoFailureMessage(mapped(error))
        }
    }

    private func apply(_ mutation: FeedMutation) {
        onPatch?(mutation.patch)
        if let version = mutation.patch.spirit?.version {
            spiritVersion = version
        }
        if let quotas = mutation.patch.quotas, !quotas.isEmpty {
            if quotas.contains(where: { $0.capability == .food }) {
                foodQuotaText = FeedPresentationRules.foodQuotaText(from: quotas)
            }
            if quotas.contains(where: { $0.capability == .sight }) {
                sightQuotaText = FeedPresentationRules.quotaText(
                    for: .sight,
                    from: quotas,
                    defaultLimit: 2
                )
            }
        }
    }

    private func requestUploadTicket(
        feedID: UUID,
        photo: ProcessedSightPhoto,
        clientID: UUID
    ) async throws -> SightUploadTicket {
        do {
            return try await feedService.requestSightUploadURL(
                feedID: feedID,
                sizeBytes: photo.jpeg.count,
                sha256: photo.sha256,
                clientID: clientID
            )
        } catch let error as AppError where error == .idempotencyConflict {
            try await forget(FeedClientIDStore.sightPhotoUploadKey)
            let retryID = try await stableID(FeedClientIDStore.sightPhotoUploadKey)
            return try await feedService.requestSightUploadURL(
                feedID: feedID,
                sizeBytes: photo.jpeg.count,
                sha256: photo.sha256,
                clientID: retryID
            )
        }
    }

    private func stableID(_ key: String) async throws -> UUID {
        guard let clientIDs, let accountUserID else {
            return UUID()
        }
        return try await clientIDs.clientID(for: key, accountUserID: accountUserID)
    }

    private func forget(_ key: String) async throws {
        guard let clientIDs, let accountUserID else { return }
        try await clientIDs.forget(key: key, accountUserID: accountUserID)
    }

    private func rememberPromise(id: UUID, text: String, remindAt: Date) async throws {
        guard let clientIDs else { return }
        try await clientIDs.rememberPromise(
            id: id,
            text: text,
            remindAt: remindAt,
            accountUserID: try accountID()
        )
    }

    private func accountID() throws -> UUID {
        guard let accountUserID else {
            throw AppError.unauthenticated
        }
        return accountUserID
    }

    private func mapped(_ error: Error) -> AppError {
        error as? AppError ?? .unknown(requestID: "")
    }

    private func photoFailureMessage(_ error: AppError) -> String {
        switch error {
        case .modelUnavailable, .networkUnavailable, .timedOut, .conflict, .sightUploadUnavailable:
            return ErrorCopy.app(error).message
        default:
            return ErrorCopy.app(error).message
        }
    }
}
