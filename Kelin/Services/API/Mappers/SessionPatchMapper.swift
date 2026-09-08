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
            serverTime: serverTime
        )
    }

    static func map(_ mutation: MutationResultDTO, serverTime: Date? = nil) throws -> SessionPatch {
        try map(mutation.patch, serverTime: serverTime)
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
