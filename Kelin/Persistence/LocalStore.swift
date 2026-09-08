import Foundation
import SwiftData

@ModelActor
actor LocalStore {
    func upsertBootstrap(_ record: CachedBootstrapRecord) throws {
        let accountUserID = record.accountUserID
        var descriptor = FetchDescriptor<CachedBootstrap>(
            predicate: #Predicate { $0.accountUserID == accountUserID }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.payloadData = record.payloadData
            existing.snapshotVersion = record.snapshotVersion
            existing.updatedAt = record.updatedAt
        } else {
            modelContext.insert(
                CachedBootstrap(
                    accountUserID: record.accountUserID,
                    payloadData: record.payloadData,
                    snapshotVersion: record.snapshotVersion,
                    updatedAt: record.updatedAt
                )
            )
        }

        try modelContext.save()
    }

    func fetchBootstrap(accountUserID: UUID) throws -> CachedBootstrapRecord? {
        let targetAccountUserID = accountUserID
        var descriptor = FetchDescriptor<CachedBootstrap>(
            predicate: #Predicate { $0.accountUserID == targetAccountUserID }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.map(Self.bootstrapRecord)
    }

    func upsertMessage(_ record: CachedMessageRecord) throws {
        try upsertMessageModel(record)
        try enforceMessageLimits(accountUserID: record.accountUserID)
        try modelContext.save()
    }

    func fetchMessages(accountUserID: UUID) throws -> [CachedMessageRecord] {
        let targetAccountUserID = accountUserID
        let descriptor = FetchDescriptor<CachedMessage>(
            predicate: #Predicate { $0.accountUserID == targetAccountUserID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(Self.messageRecord)
    }

    func upsertMemory(_ record: CachedMemoryRecord) throws {
        try upsertMemoryModel(record)
        try enforceMemoryLimits(accountUserID: record.accountUserID)
        try modelContext.save()
    }

    func tombstoneMemory(id: UUID, accountUserID: UUID, updatedAt: Date) throws {
        let targetID = id
        let targetAccountUserID = accountUserID
        var descriptor = FetchDescriptor<CachedMemory>(
            predicate: #Predicate { memory in
                memory.id == targetID && memory.accountUserID == targetAccountUserID
            }
        )
        descriptor.fetchLimit = 1

        guard let memory = try modelContext.fetch(descriptor).first else {
            return
        }

        memory.isTombstone = true
        memory.updatedAt = updatedAt
        try modelContext.save()
    }

    func fetchActiveMemories(accountUserID: UUID) throws -> [CachedMemoryRecord] {
        let targetAccountUserID = accountUserID
        let descriptor = FetchDescriptor<CachedMemory>(
            predicate: #Predicate { memory in
                memory.accountUserID == targetAccountUserID && memory.isTombstone == false
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(Self.memoryRecord)
    }

    func fetchTombstonedMemories(accountUserID: UUID) throws -> [CachedMemoryRecord] {
        let targetAccountUserID = accountUserID
        let descriptor = FetchDescriptor<CachedMemory>(
            predicate: #Predicate { memory in
                memory.accountUserID == targetAccountUserID && memory.isTombstone == true
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(Self.memoryRecord)
    }

    func upsertPostcard(_ record: CachedPostcardRecord) throws {
        try upsertPostcardModel(record)
        try enforcePostcardLimits(accountUserID: record.accountUserID)
        try modelContext.save()
    }

    func fetchPostcards(accountUserID: UUID) throws -> [CachedPostcardRecord] {
        let targetAccountUserID = accountUserID
        let descriptor = FetchDescriptor<CachedPostcard>(
            predicate: #Predicate { $0.accountUserID == targetAccountUserID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(Self.postcardRecord)
    }

    func upsertPact(_ record: CachedPactRecord) throws {
        try upsertPactModel(record)
        try modelContext.save()
    }

    func fetchPacts(accountUserID: UUID) throws -> [CachedPactRecord] {
        let targetAccountUserID = accountUserID
        let descriptor = FetchDescriptor<CachedPact>(
            predicate: #Predicate { $0.accountUserID == targetAccountUserID },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(Self.pactRecord)
    }

    func upsertDraft(_ record: DraftRecord) throws {
        try upsertDraftModel(record)
        try modelContext.save()
    }

    func fetchDrafts(accountUserID: UUID) throws -> [DraftRecord] {
        let targetAccountUserID = accountUserID
        let descriptor = FetchDescriptor<Draft>(
            predicate: #Predicate { $0.accountUserID == targetAccountUserID },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(Self.draftRecord)
    }

    func deleteDraft(id: UUID, accountUserID: UUID) throws {
        let targetID = id
        let targetAccountUserID = accountUserID
        var descriptor = FetchDescriptor<Draft>(
            predicate: #Predicate { draft in
                draft.id == targetID && draft.accountUserID == targetAccountUserID
            }
        )
        descriptor.fetchLimit = 1

        if let draft = try modelContext.fetch(descriptor).first {
            modelContext.delete(draft)
            try modelContext.save()
        }
    }

    func upsertPendingOperation(_ record: PendingOperationRecord) throws {
        try upsertPendingOperationModel(record)
        try modelContext.save()
    }

    func fetchPendingOperations(accountUserID: UUID) throws -> [PendingOperationRecord] {
        let targetAccountUserID = accountUserID
        let descriptor = FetchDescriptor<PendingOperation>(
            predicate: #Predicate { $0.accountUserID == targetAccountUserID },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor).map(Self.pendingOperationRecord)
    }

    func deletePendingOperation(id: UUID, accountUserID: UUID) throws {
        let targetID = id
        let targetAccountUserID = accountUserID
        var descriptor = FetchDescriptor<PendingOperation>(
            predicate: #Predicate { operation in
                operation.id == targetID && operation.accountUserID == targetAccountUserID
            }
        )
        descriptor.fetchLimit = 1

        if let operation = try modelContext.fetch(descriptor).first {
            modelContext.delete(operation)
            try modelContext.save()
        }
    }

    func clearAccount(accountUserID: UUID) throws {
        let targetAccountUserID = accountUserID

        for bootstrap in try modelContext.fetch(
            FetchDescriptor<CachedBootstrap>(
                predicate: #Predicate { $0.accountUserID == targetAccountUserID }
            )
        ) {
            modelContext.delete(bootstrap)
        }

        for message in try modelContext.fetch(
            FetchDescriptor<CachedMessage>(
                predicate: #Predicate { $0.accountUserID == targetAccountUserID }
            )
        ) {
            modelContext.delete(message)
        }

        for memory in try modelContext.fetch(
            FetchDescriptor<CachedMemory>(
                predicate: #Predicate { $0.accountUserID == targetAccountUserID }
            )
        ) {
            modelContext.delete(memory)
        }

        for postcard in try modelContext.fetch(
            FetchDescriptor<CachedPostcard>(
                predicate: #Predicate { $0.accountUserID == targetAccountUserID }
            )
        ) {
            modelContext.delete(postcard)
        }

        for pact in try modelContext.fetch(
            FetchDescriptor<CachedPact>(
                predicate: #Predicate { $0.accountUserID == targetAccountUserID }
            )
        ) {
            modelContext.delete(pact)
        }

        for draft in try modelContext.fetch(
            FetchDescriptor<Draft>(
                predicate: #Predicate { $0.accountUserID == targetAccountUserID }
            )
        ) {
            modelContext.delete(draft)
        }

        for operation in try modelContext.fetch(
            FetchDescriptor<PendingOperation>(
                predicate: #Predicate { $0.accountUserID == targetAccountUserID }
            )
        ) {
            modelContext.delete(operation)
        }

        try modelContext.save()
    }

    private func upsertMessageModel(_ record: CachedMessageRecord) throws {
        let recordID = record.id
        let accountUserID = record.accountUserID
        var descriptor = FetchDescriptor<CachedMessage>(
            predicate: #Predicate { message in
                message.id == recordID && message.accountUserID == accountUserID
            }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.clientID = record.clientID
            existing.payloadData = record.payloadData
            existing.sendState = record.sendState
            existing.createdAt = record.createdAt
        } else {
            modelContext.insert(
                CachedMessage(
                    id: record.id,
                    accountUserID: record.accountUserID,
                    clientID: record.clientID,
                    payloadData: record.payloadData,
                    sendState: record.sendState,
                    createdAt: record.createdAt
                )
            )
        }
    }

    private func upsertMemoryModel(_ record: CachedMemoryRecord) throws {
        let recordID = record.id
        let accountUserID = record.accountUserID
        var descriptor = FetchDescriptor<CachedMemory>(
            predicate: #Predicate { memory in
                memory.id == recordID && memory.accountUserID == accountUserID
            }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.payloadData = record.payloadData
            existing.isTombstone = record.isTombstone
            existing.updatedAt = record.updatedAt
        } else {
            modelContext.insert(
                CachedMemory(
                    id: record.id,
                    accountUserID: record.accountUserID,
                    payloadData: record.payloadData,
                    isTombstone: record.isTombstone,
                    updatedAt: record.updatedAt
                )
            )
        }
    }

    private func upsertPostcardModel(_ record: CachedPostcardRecord) throws {
        let recordID = record.id
        let accountUserID = record.accountUserID
        var descriptor = FetchDescriptor<CachedPostcard>(
            predicate: #Predicate { postcard in
                postcard.id == recordID && postcard.accountUserID == accountUserID
            }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.payloadData = record.payloadData
            existing.isRead = record.isRead
            existing.createdAt = record.createdAt
        } else {
            modelContext.insert(
                CachedPostcard(
                    id: record.id,
                    accountUserID: record.accountUserID,
                    payloadData: record.payloadData,
                    isRead: record.isRead,
                    createdAt: record.createdAt
                )
            )
        }
    }

    private func upsertPactModel(_ record: CachedPactRecord) throws {
        let recordID = record.id
        let accountUserID = record.accountUserID
        var descriptor = FetchDescriptor<CachedPact>(
            predicate: #Predicate { pact in
                pact.id == recordID && pact.accountUserID == accountUserID
            }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.payloadData = record.payloadData
            existing.updatedAt = record.updatedAt
        } else {
            modelContext.insert(
                CachedPact(
                    id: record.id,
                    accountUserID: record.accountUserID,
                    payloadData: record.payloadData,
                    updatedAt: record.updatedAt
                )
            )
        }
    }

    private func upsertDraftModel(_ record: DraftRecord) throws {
        let recordID = record.id
        let accountUserID = record.accountUserID
        var descriptor = FetchDescriptor<Draft>(
            predicate: #Predicate { draft in
                draft.id == recordID && draft.accountUserID == accountUserID
            }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.kind = record.kind
            existing.payloadData = record.payloadData
            existing.updatedAt = record.updatedAt
        } else {
            modelContext.insert(
                Draft(
                    id: record.id,
                    accountUserID: record.accountUserID,
                    kind: record.kind,
                    payloadData: record.payloadData,
                    updatedAt: record.updatedAt
                )
            )
        }
    }

    private func upsertPendingOperationModel(_ record: PendingOperationRecord) throws {
        let recordID = record.id
        let accountUserID = record.accountUserID
        var descriptor = FetchDescriptor<PendingOperation>(
            predicate: #Predicate { operation in
                operation.id == recordID && operation.accountUserID == accountUserID
            }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.kind = record.kind
            existing.clientID = record.clientID
            existing.payloadData = record.payloadData
            existing.createdAt = record.createdAt
            existing.attemptCount = record.attemptCount
            existing.nextRetryAt = record.nextRetryAt
            existing.lastErrorCode = record.lastErrorCode
            existing.state = record.state
        } else {
            modelContext.insert(
                PendingOperation(
                    id: record.id,
                    accountUserID: record.accountUserID,
                    kind: record.kind,
                    clientID: record.clientID,
                    payloadData: record.payloadData,
                    createdAt: record.createdAt,
                    attemptCount: record.attemptCount,
                    nextRetryAt: record.nextRetryAt,
                    lastErrorCode: record.lastErrorCode,
                    state: record.state
                )
            )
        }
    }

    private func enforceMessageLimits(accountUserID: UUID) throws {
        let targetAccountUserID = accountUserID
        let descriptor = FetchDescriptor<CachedMessage>(
            predicate: #Predicate { $0.accountUserID == targetAccountUserID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let messages = try modelContext.fetch(descriptor)

        var retainedSent = 0
        for message in messages {
            if message.sendState == .sent {
                retainedSent += 1
                if retainedSent > LocalStoreLimits.maxSentMessages {
                    modelContext.delete(message)
                }
            }
        }
    }

    private func enforceMemoryLimits(accountUserID: UUID) throws {
        let targetAccountUserID = accountUserID
        let descriptor = FetchDescriptor<CachedMemory>(
            predicate: #Predicate { memory in
                memory.accountUserID == targetAccountUserID && memory.isTombstone == false
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let memories = try modelContext.fetch(descriptor)

        if memories.count > LocalStoreLimits.maxActiveMemories {
            for memory in memories.dropFirst(LocalStoreLimits.maxActiveMemories) {
                modelContext.delete(memory)
            }
        }
    }

    private func enforcePostcardLimits(accountUserID: UUID) throws {
        let targetAccountUserID = accountUserID
        let descriptor = FetchDescriptor<CachedPostcard>(
            predicate: #Predicate { $0.accountUserID == targetAccountUserID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let postcards = try modelContext.fetch(descriptor)

        var retainedRead = 0
        for postcard in postcards {
            if postcard.isRead {
                retainedRead += 1
                if retainedRead > LocalStoreLimits.maxReadPostcards {
                    modelContext.delete(postcard)
                }
            }
        }
    }
}

private extension LocalStore {
    static func bootstrapRecord(from model: CachedBootstrap) -> CachedBootstrapRecord {
        CachedBootstrapRecord(
            accountUserID: model.accountUserID,
            payloadData: model.payloadData,
            snapshotVersion: model.snapshotVersion,
            updatedAt: model.updatedAt
        )
    }

    static func messageRecord(from model: CachedMessage) -> CachedMessageRecord {
        CachedMessageRecord(
            id: model.id,
            accountUserID: model.accountUserID,
            clientID: model.clientID,
            payloadData: model.payloadData,
            sendState: model.sendState,
            createdAt: model.createdAt
        )
    }

    static func memoryRecord(from model: CachedMemory) -> CachedMemoryRecord {
        CachedMemoryRecord(
            id: model.id,
            accountUserID: model.accountUserID,
            payloadData: model.payloadData,
            isTombstone: model.isTombstone,
            updatedAt: model.updatedAt
        )
    }

    static func postcardRecord(from model: CachedPostcard) -> CachedPostcardRecord {
        CachedPostcardRecord(
            id: model.id,
            accountUserID: model.accountUserID,
            payloadData: model.payloadData,
            isRead: model.isRead,
            createdAt: model.createdAt
        )
    }

    static func pactRecord(from model: CachedPact) -> CachedPactRecord {
        CachedPactRecord(
            id: model.id,
            accountUserID: model.accountUserID,
            payloadData: model.payloadData,
            updatedAt: model.updatedAt
        )
    }

    static func draftRecord(from model: Draft) -> DraftRecord {
        DraftRecord(
            id: model.id,
            accountUserID: model.accountUserID,
            kind: model.kind,
            payloadData: model.payloadData,
            updatedAt: model.updatedAt
        )
    }

    static func pendingOperationRecord(from model: PendingOperation) -> PendingOperationRecord {
        PendingOperationRecord(
            id: model.id,
            accountUserID: model.accountUserID,
            kind: model.kind,
            clientID: model.clientID,
            payloadData: model.payloadData,
            createdAt: model.createdAt,
            attemptCount: model.attemptCount,
            nextRetryAt: model.nextRetryAt,
            lastErrorCode: model.lastErrorCode,
            state: model.state
        )
    }
}
