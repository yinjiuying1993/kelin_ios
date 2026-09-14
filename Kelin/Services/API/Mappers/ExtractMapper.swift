import Foundation

enum ExtractMapper {
    static func makeRequest(clientID: UUID, conversationWindowID: UUID) -> ExtractRequestDTO {
        ExtractRequestDTO(clientID: clientID, conversationWindowID: conversationWindowID)
    }

    static func map(_ dto: ExtractMutationResultDTO, serverTime: Date) throws -> ExtractResult {
        guard let status = ExtractStatus(rawValue: dto.resource.status) else {
            throw AppError.decoding
        }

        return ExtractResult(
            status: status,
            memories: dto.resource.memories.map(BootstrapMapper.mapMemory),
            patch: try SessionPatchMapper.attachingQuotas(
                try SessionPatchMapper.map(dto.patch, serverTime: serverTime),
                from: dto.quotas
            )
        )
    }
}
