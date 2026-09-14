import Foundation

enum MemoryConfirm: Equatable, Identifiable {
    case correct
    case seal
    case delete
    case clearAll

    var id: String {
        switch self {
        case .correct: "correct"
        case .seal: "seal"
        case .delete: "delete"
        case .clearAll: "clearAll"
        }
    }
}

@MainActor
@Observable
final class MemoryViewModel {
    var filter: MemoryFilter = .all
    var selectedMemoryID: UUID?
    var correctionDraft = ""
    var confirm: MemoryConfirm?

    private(set) var memories: [MemorySummary]
    private(set) var spiritName: String
    private(set) var isOffline: Bool
    private(set) var isLoading = false
    private(set) var isMutating = false
    private(set) var hasMore = false
    private(set) var loadError: AppError?
    private(set) var mutationError: AppError?

    private let memoryService: any MemoryServiceProtocol
    private let localStore: LocalStore?
    private let clientIDs: MemoryClientIDStore?
    private let accountUserID: UUID?
    private let onPatch: ((SessionPatch) -> Void)?
    private var nextCursor: String?
    private var didRetryInvalidCursor = false

    init(
        memories: [MemorySummary],
        spiritName: String,
        isOffline: Bool,
        memoryService: any MemoryServiceProtocol = MockMemoryService(),
        localStore: LocalStore? = nil,
        clientIDs: MemoryClientIDStore? = nil,
        accountUserID: UUID? = nil,
        onPatch: ((SessionPatch) -> Void)? = nil
    ) {
        self.memories = memories
        self.spiritName = spiritName
        self.isOffline = isOffline
        self.memoryService = memoryService
        self.localStore = localStore
        self.clientIDs = clientIDs
        self.accountUserID = accountUserID
        self.onPatch = onPatch
    }

    var groups: [MemoryDayGroup] {
        MemoryPresentationRules.groups(
            from: memories,
            filter: .all,
            now: Date(),
            calendar: .current
        )
    }

    var isEmpty: Bool {
        filter == .all
            && memories.isEmpty
            && loadError == nil
            && !isLoading
    }

    var hasNoFilterMatches: Bool {
        filter != .all
            && memories.isEmpty
            && loadError == nil
            && !isLoading
    }

    var selectedItem: MemoryTimelineItem? {
        guard let selectedMemoryID,
              let memory = memories.first(where: { $0.id == selectedMemoryID })
        else {
            return nil
        }
        return MemoryPresentationRules.timelineItem(from: memory)
    }

    var canClearAll: Bool {
        MemoryMutationRules.canClearAll(isOffline: isOffline) && !memories.isEmpty && !isMutating
    }

    func select(_ id: UUID) {
        selectedMemoryID = id
        if let memory = memories.first(where: { $0.id == id }) {
            correctionDraft = memory.summary
        }
        mutationError = nil
    }

    func dismissDetail() {
        selectedMemoryID = nil
        confirm = nil
        correctionDraft = ""
    }

    func applySnapshotUpdate(
        memories: [MemorySummary]? = nil,
        spiritName: String,
        isOffline: Bool
    ) {
        if let memories {
            self.memories = MemoryCacheRules.rejectResurrection(memories, hiddenIDs: [])
        }
        self.spiritName = spiritName
        self.isOffline = isOffline
    }

    func setFilter(_ filter: MemoryFilter) async {
        guard self.filter != filter else { return }
        self.filter = filter
        nextCursor = nil
        hasMore = false
        didRetryInvalidCursor = false
        await load(reset: true)
    }

    func loadInitial() async {
        await loadCachedPreview()
        await load(reset: true)
    }

    func loadMore() async {
        guard hasMore, nextCursor != nil, !isLoading else { return }
        await load(reset: false)
    }

    func refresh() async {
        didRetryInvalidCursor = false
        await load(reset: true)
    }

    func submitCorrect() async {
        guard let memory = selectedMemory else { return }
        do {
            let summary = try MemoryMutationRules.validateSummary(correctionDraft)
            try await runMutation(key: MemoryClientIDStore.correctKey(memory.id)) { clientID in
                try await memoryService.correct(
                    id: memory.id,
                    expectedVersion: memory.version,
                    summary: summary,
                    clientID: clientID
                )
            }
            confirm = nil
        } catch let error as AppError {
            mutationError = error
        } catch {
            mutationError = .unknown(requestID: "")
        }
    }

    func submitSeal() async {
        guard let memory = selectedMemory else { return }
        await submitSimpleMutation(key: MemoryClientIDStore.sealKey(memory.id)) { clientID in
            try await memoryService.seal(
                id: memory.id,
                expectedVersion: memory.version,
                clientID: clientID
            )
        }
    }

    func submitDelete() async {
        guard let memory = selectedMemory else { return }
        await submitSimpleMutation(key: MemoryClientIDStore.deleteKey(memory.id)) { clientID in
            try await memoryService.delete(
                id: memory.id,
                expectedVersion: memory.version,
                clientID: clientID
            )
        }
    }

    func submitClearAll() async {
        guard canClearAll else {
            mutationError = .networkUnavailable
            return
        }
        await submitSimpleMutation(key: MemoryClientIDStore.clearKey) { clientID in
            try await memoryService.clearAll(clientID: clientID)
        }
    }

    private var selectedMemory: MemorySummary? {
        guard let selectedMemoryID else { return nil }
        return memories.first(where: { $0.id == selectedMemoryID })
    }

    private func submitSimpleMutation(
        key: String,
        work: (UUID) async throws -> MemoryMutation
    ) async {
        do {
            try await runMutation(key: key, work: work)
            confirm = nil
            if key == MemoryClientIDStore.clearKey || key.hasPrefix("seal:") || key.hasPrefix("delete:") {
                dismissDetail()
            }
        } catch let error as AppError {
            mutationError = error
        } catch {
            mutationError = .unknown(requestID: "")
        }
    }

    private func runMutation(
        key: String,
        work: (UUID) async throws -> MemoryMutation
    ) async throws {
        guard !isOffline || key != MemoryClientIDStore.clearKey else {
            throw AppError.networkUnavailable
        }

        isMutating = true
        defer { isMutating = false }

        let clientID: UUID
        if let clientIDs, let accountUserID {
            clientID = try await clientIDs.clientID(for: key, accountUserID: accountUserID)
        } else {
            clientID = UUID()
        }

        let mutation = try await work(clientID)
        memories = MemoryCacheRules.applyMutation(existing: memories, mutation: mutation)
        onPatch?(mutation.patch)
        await persist(mutation: mutation)
        if let clientIDs, let accountUserID {
            try? await clientIDs.forget(key: key, accountUserID: accountUserID)
        }
        mutationError = nil
    }

    private func load(reset: Bool) async {
        if isOffline {
            await loadCachedPreview()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let page = try await memoryService.list(
                filter: filter,
                cursor: reset ? nil : nextCursor,
                limit: 30
            )
            if reset {
                memories = MemoryCacheRules.merge(existing: [], incoming: page.items, tombstones: page.tombstones)
            } else {
                memories = MemoryCacheRules.merge(
                    existing: memories,
                    incoming: page.items,
                    tombstones: page.tombstones
                )
            }
            nextCursor = page.nextCursor
            hasMore = page.hasMore
            loadError = nil
            await persist(page: page, replace: reset)
        } catch AppError.invalidCursor {
            nextCursor = nil
            hasMore = false
            if !didRetryInvalidCursor {
                didRetryInvalidCursor = true
                await load(reset: true)
            } else {
                loadError = .invalidCursor
            }
        } catch let error as AppError {
            loadError = error
            if reset {
                await loadCachedPreview()
            }
        } catch {
            loadError = .unknown(requestID: "")
        }
    }

    private func loadCachedPreview() async {
        guard let localStore, let accountUserID else { return }
        do {
            let records = try await localStore.fetchActiveMemories(accountUserID: accountUserID)
            let tombstoned = try await localStore.fetchTombstonedMemories(accountUserID: accountUserID)
            let hidden = Set(tombstoned.map(\.id))
            let cached = records.compactMap { try? MemoryCodec.decode($0.payloadData) }
            memories = MemoryCacheRules.rejectResurrection(cached, hiddenIDs: hidden)
                .filter { MemoryPresentationRules.matches($0, filter: filter) }
        } catch {
            return
        }
    }

    private func persist(page: MemoryPage, replace: Bool) async {
        guard let localStore, let accountUserID else { return }
        do {
            if replace, page.tombstones.isEmpty, page.items.isEmpty, filter == .all {
                try await localStore.clearMemories(accountUserID: accountUserID)
            }
            for item in page.items {
                try await localStore.upsertMemory(
                    CachedMemoryRecord(
                        id: item.id,
                        accountUserID: accountUserID,
                        payloadData: MemoryCodec.encode(item),
                        isTombstone: false,
                        updatedAt: item.createdAt
                    )
                )
            }
            for tombstone in page.tombstones {
                try await localStore.tombstoneMemory(
                    id: tombstone.id,
                    accountUserID: accountUserID,
                    updatedAt: tombstone.deletedAt
                )
            }
        } catch {
            return
        }
    }

    private func persist(mutation: MemoryMutation) async {
        guard let localStore, let accountUserID else { return }
        do {
            if mutation.patch.clearsAllMemories || mutation.resourceType == "memory_clear" {
                try await localStore.clearMemories(accountUserID: accountUserID)
                return
            }
            for item in mutation.patch.memoriesUpsert {
                try await localStore.upsertMemory(
                    CachedMemoryRecord(
                        id: item.id,
                        accountUserID: accountUserID,
                        payloadData: try MemoryCodec.encode(item),
                        isTombstone: !MemoryPresentationRules.isListable(item),
                        updatedAt: Date()
                    )
                )
            }
            for tombstone in mutation.patch.memoryTombstones {
                if let existing = try await localStore.fetchActiveMemories(accountUserID: accountUserID)
                    .first(where: { $0.id == tombstone.id }) {
                    try await localStore.upsertMemory(
                        CachedMemoryRecord(
                            id: existing.id,
                            accountUserID: accountUserID,
                            payloadData: Data(),
                            isTombstone: true,
                            updatedAt: tombstone.deletedAt
                        )
                    )
                } else {
                    try await localStore.tombstoneMemory(
                        id: tombstone.id,
                        accountUserID: accountUserID,
                        updatedAt: tombstone.deletedAt
                    )
                }
            }
        } catch {
            return
        }
    }
}
