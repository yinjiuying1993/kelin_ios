import Foundation

enum FeedMapper {
    static func map(_ dto: FeedMutationResultDTO, serverTime: Date?) throws -> FeedMutation {
        guard P12FeedContractManifest.requiredKinds.contains(dto.resource.kind) else {
            throw AppError.decoding
        }
        guard P12FeedContractManifest.requiredStatuses.contains(dto.resource.status) else {
            throw AppError.decoding
        }
        if let prop = dto.prop, !P12FeedContractManifest.sightPropWhitelist.contains(prop) {
            throw AppError.decoding
        }

        let mappedQuotas = try dto.quotas.map { try $0.map(BootstrapMapper.mapQuota) }
        let patch = try SessionPatchMapper.attachingQuotas(
            try SessionPatchMapper.map(dto.patch, serverTime: serverTime),
            from: dto.quotas
        )

        return FeedMutation(
            resource: FeedResource(
                id: dto.resource.id,
                version: dto.resource.version,
                kind: dto.resource.kind,
                status: dto.resource.status,
                promiseStatus: dto.resource.promiseStatus
            ),
            patch: patch,
            quotas: mappedQuotas ?? [],
            events: dto.events.map {
                MutationEvent(id: $0.id, type: $0.type, occurredAt: $0.occurredAt)
            },
            prop: dto.prop
        )
    }

    static func mapUpload(_ dto: SightUploadURLResultDTO) throws -> SightUploadTicket {
        guard dto.method == "PUT" else {
            throw AppError.decoding
        }
        guard let url = URL(string: dto.url) else {
            throw AppError.decoding
        }
        guard FeedPresentationRules.isFourSegmentSightPath(dto.objectPath) else {
            throw AppError.decoding
        }
        guard (1...5_242_880).contains(dto.maxSizeBytes) else {
            throw AppError.decoding
        }

        return SightUploadTicket(
            uploadSessionID: dto.uploadSessionID,
            method: dto.method,
            url: url,
            headers: dto.headers,
            objectPath: dto.objectPath,
            expiresAt: dto.expiresAt,
            maxSizeBytes: dto.maxSizeBytes
        )
    }
}
