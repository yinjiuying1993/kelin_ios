import Foundation

enum SessionPatchMapper {
    static func map(_ dto: SessionPatchDTO, serverTime: Date? = nil) throws -> SessionPatch {
        let spirit = try dto.spirit.map { spiritDTO in
            try SpiritMapper.mapSpirit(
                spiritDTO,
                preferences: spiritDTO.preferences ?? dto.preferences ?? defaultPreferences()
            )
        }

        let preferences: SpiritPreferences?
        if dto.spirit == nil, let preferenceDTO = dto.preferences {
            preferences = mapPreferences(preferenceDTO)
        } else {
            preferences = nil
        }

        return SessionPatch(
            snapshotVersion: dto.snapshotVersion,
            spirit: spirit,
            preferences: preferences,
            room: dto.room.map(BootstrapMapper.mapRoom),
            onboarding: dto.onboarding.map(BootstrapMapper.mapOnboarding),
            memoriesUpsert: dto.memoriesUpsert.map(BootstrapMapper.mapMemory),
            memoryTombstones: try dto.memoryTombstones.map(MemoryMapper.mapTombstone),
            pact: try dto.pact.map(PactMapper.mapPact),
            social: try dto.social.map(SocialMapper.mapSocialPatch),
            postcardsUpsert: try dto.postcardsUpsert.map(SocialMapper.mapPostcard),
            report: try dto.report.map(ReportMapper.mapSnapshot),
            serverTime: serverTime
        )
    }

    static func attachingQuotas(_ patch: SessionPatch, from dtos: [QuotaEntryDTO]?) throws -> SessionPatch {
        guard let dtos else {
            return patch
        }

        return SessionPatch(
            snapshotVersion: patch.snapshotVersion,
            spirit: patch.spirit,
            preferences: patch.preferences,
            room: patch.room,
            onboarding: patch.onboarding,
            memoriesUpsert: patch.memoriesUpsert,
            memoryTombstones: patch.memoryTombstones,
            clearsAllMemories: patch.clearsAllMemories,
            quotas: try dtos.map(BootstrapMapper.mapQuota),
            pact: patch.pact,
            social: patch.social,
            postcardsUpsert: patch.postcardsUpsert,
            report: patch.report,
            serverTime: patch.serverTime
        )
    }

    static func map(_ mutation: MutationResultDTO, serverTime: Date? = nil) throws -> SessionPatch {
        var patch = try map(mutation.patch, serverTime: serverTime)
        if mutation.resource.type == "memory_clear" {
            patch = SessionPatch(
                snapshotVersion: patch.snapshotVersion,
                spirit: patch.spirit,
                preferences: patch.preferences,
                room: patch.room,
                onboarding: patch.onboarding,
                memoriesUpsert: patch.memoriesUpsert,
                memoryTombstones: patch.memoryTombstones,
                clearsAllMemories: true,
                pact: patch.pact,
                social: patch.social,
                postcardsUpsert: patch.postcardsUpsert,
                report: patch.report,
                serverTime: patch.serverTime
            )
        }
        return patch
    }

    private static func mapPreferences(_ dto: PreferencesDTO) -> SpiritPreferences {
        SpiritPreferences(
            ttsOn: dto.ttsOn,
            pushOn: dto.pushOn,
            visitOn: dto.visitOn,
            dndStart: dto.dndStart,
            dndEnd: dto.dndEnd,
            timezone: dto.timezone,
            defaultCity: dto.defaultCity,
            locationWeatherOn: dto.locationWeatherOn,
            remoteSearchOn: dto.remoteSearchOn
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
