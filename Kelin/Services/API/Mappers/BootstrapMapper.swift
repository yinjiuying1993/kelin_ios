import Foundation

enum BootstrapMapper {
    static func map(_ envelope: APIEnvelope<BootstrapDataDTO>) throws -> BootstrapSnapshot {
        guard envelope.ok, let data = envelope.data else {
            if let errorPayload = envelope.error {
                throw APIErrorMapper.map(errorPayload, requestID: envelope.requestID)
            }
            throw AppError.decoding
        }

        return try map(data, serverTime: envelope.serverTime)
    }

    static func map(_ dto: BootstrapDataDTO, serverTime: Date) throws -> BootstrapSnapshot {
        let spirit = try dto.spirit.map { spiritDTO in
            try SpiritMapper.mapSpirit(
                spiritDTO,
                preferences: spiritDTO.preferences ?? defaultPreferences()
            )
        }

        let room = dto.room.map(mapRoom)

        return BootstrapSnapshot(
            schemaVersion: dto.schemaVersion,
            snapshotVersion: dto.snapshotVersion,
            apiVersion: dto.apiVersion,
            spirit: spirit,
            room: room,
            onboarding: mapOnboarding(dto.onboarding),
            latestMemories: dto.latestMemories.map(mapMemory),
            unreadPostcards: dto.unreadPostcards.map(mapPostcard),
            activePact: dto.activePact.map(mapPact),
            report: try ReportMapper.mapSnapshot(dto.report),
            quotas: try dto.quotas.map(mapQuota),
            featureFlags: mapFeatureFlags(dto.featureFlags),
            serverTime: serverTime
        )
    }

    static func mapRoom(_ dto: RoomSnapshotDTO) -> RoomSnapshot {
        RoomSnapshot(
            weather: dto.weather,
            layers: dto.layers.map { RoomLayer(key: $0.key, variant: $0.variant) },
            letter: dto.letter,
            pendingSightID: dto.pendingSight?.id,
            unreadFootprintCount: dto.unreadFootprintCount,
            updatedAt: dto.updatedAt
        )
    }

    static func mapOnboarding(_ dto: OnboardingDTO) -> OnboardingState {
        OnboardingState(
            required: dto.required,
            step: dto.step,
            totalSteps: dto.totalSteps,
            completedAt: dto.completedAt
        )
    }

    static func mapMemory(_ dto: MemorySummaryDTO) -> MemorySummary {
        MemorySummary(
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

    private static func mapPostcard(_ dto: PostcardSummaryDTO) -> PostcardSummary {
        PostcardSummary(
            id: dto.id,
            text: dto.text,
            createdAt: dto.createdAt
        )
    }

    private static func mapPact(_ dto: PactSummaryDTO) -> PactSummary {
        PactSummary(
            id: dto.id,
            theme: dto.theme,
            title: dto.title,
            status: dto.status
        )
    }

    static func mapQuota(_ dto: QuotaEntryDTO) throws -> QuotaEntry {
        guard let capability = QuotaKind(rawValue: dto.capability) else {
            throw AppError.decoding
        }

        return QuotaEntry(
            capability: capability,
            used: dto.used,
            limit: dto.limit,
            resetAt: dto.resetAt
        )
    }

    private static func mapFeatureFlags(_ dto: FeatureFlagsDTO) -> FeatureFlags {
        FeatureFlags(
            remoteSearch: dto.remoteSearch,
            imageFeed: dto.imageFeed
        )
    }

    private static func defaultPreferences() -> PreferencesDTO {
        PreferencesDTO(
            ttsOn: false,
            pushOn: false,
            visitOn: true,
            dndStart: "23:00",
            dndEnd: "08:00",
            timezone: "Asia/Shanghai",
            defaultCity: nil,
            locationWeatherOn: false,
            remoteSearchOn: true
        )
    }
}
