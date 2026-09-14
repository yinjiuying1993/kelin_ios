import Foundation

enum MemoryMapper {
    static func mapPage(_ dto: MemoryPageDTO) throws -> MemoryPage {
        MemoryPage(
            items: try dto.items.map(mapPublic),
            tombstones: try dto.tombstones.map(mapTombstone),
            nextCursor: dto.nextCursor,
            hasMore: dto.hasMore,
            snapshotAt: dto.snapshotAt
        )
    }

    static func mapPublic(_ dto: MemoryPublicDTO) throws -> MemorySummary {
        guard P11MemoryContractManifest.memoryPublicTypeValues.contains(dto.type) else {
            throw AppError.decoding
        }
        guard P11MemoryContractManifest.memoryPublicStatusValues.contains(dto.status) else {
            throw AppError.decoding
        }
        guard (1...500).contains(dto.summary.count) else {
            throw AppError.decoding
        }
        guard (0...100).contains(dto.salience), dto.confidence >= 0, dto.confidence <= 1, dto.version >= 1 else {
            throw AppError.decoding
        }

        return MemorySummary(
            id: dto.id,
            type: dto.type,
            summary: dto.summary,
            status: dto.status,
            createdAt: dto.createdAt,
            version: dto.version,
            tags: dto.tags,
            salience: dto.salience,
            confidence: dto.confidence
        )
    }

    static func mapTombstone(_ dto: MemoryTombstoneDTO) throws -> MemoryTombstone {
        MemoryTombstone(id: dto.id, deletedAt: dto.deletedAt)
    }

    static func mapMutation(_ dto: MutationResultDTO, serverTime: Date?) throws -> MemoryMutation {
        MemoryMutation(
            resourceType: dto.resource.type,
            resourceID: dto.resource.id,
            resourceStatus: dto.resource.status,
            patch: try SessionPatchMapper.map(dto, serverTime: serverTime)
        )
    }
}
