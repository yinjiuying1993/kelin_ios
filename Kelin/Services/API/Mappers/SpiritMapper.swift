import Foundation

enum SpiritMapper {
    static func mapCreateSpiritResult(_ dto: MutationResultDTO) throws -> CreateSpiritResult {
        guard dto.resource.type == "spirit" else {
            throw AppError.decoding
        }

        guard let spiritDTO = dto.patch.spirit else {
            throw AppError.decoding
        }

        guard let onboardingDTO = dto.patch.onboarding else {
            throw AppError.decoding
        }

        let spirit = try mapSpirit(
            spiritDTO,
            preferences: dto.patch.preferences ?? defaultPreferences()
        )

        return CreateSpiritResult(
            spirit: spirit,
            onboarding: mapOnboarding(onboardingDTO),
            snapshotVersion: dto.patch.snapshotVersion
        )
    }

    static func mapSpirit(
        _ dto: SpiritDTO,
        preferences: PreferencesDTO
    ) throws -> Spirit {
        guard let egg = EggType(rawValue: dto.egg) else {
            throw AppError.decoding
        }
        guard let stage = SpiritStage(rawValue: dto.stage) else {
            throw AppError.decoding
        }
        guard let status = SpiritStatus(rawValue: dto.status) else {
            throw AppError.decoding
        }

        return Spirit(
            id: dto.id,
            userID: dto.userID,
            name: dto.name,
            egg: egg,
            inviteCode: dto.inviteCode,
            traits: TraitValues(
                closeness: dto.closeness,
                curiosity: dto.curiosity,
                sharpness: dto.sharpness,
                nocturnal: dto.nocturnal,
                stubborn: dto.stubborn
            ),
            vitals: VitalValues(
                hunger: dto.hunger,
                energy: dto.energy,
                mood: dto.mood,
                bond: dto.bond
            ),
            stage: stage,
            status: status,
            scholarMarks: dto.scholarMarks,
            preferences: mapPreferences(preferences),
            awayUntil: dto.awayUntil,
            studyUntil: dto.studyUntil,
            lastInteractAt: dto.lastInteractAt,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            version: dto.version
        )
    }

    static func mapRequest(_ input: CreateSpiritRequest) -> CreateSpiritRequestDTO {
        CreateSpiritRequestDTO(
            clientID: input.clientID,
            egg: input.egg.rawValue,
            name: input.name,
            consents: CreateSpiritConsentsDTO(
                aiDisclosure: ConsentAcceptanceDTO(
                    documentVersion: input.consents.aiDisclosure.documentVersion,
                    explicitlyAccepted: input.consents.aiDisclosure.explicitlyAccepted
                ),
                dataNotice: ConsentDisplayedDTO(
                    documentVersion: input.consents.dataNotice.documentVersion,
                    displayed: input.consents.dataNotice.displayed
                ),
                userTerms: ConsentDisplayedDTO(
                    documentVersion: input.consents.userTerms.documentVersion,
                    displayed: input.consents.userTerms.displayed
                )
            )
        )
    }

    private static func mapOnboarding(_ dto: OnboardingDTO) -> OnboardingState {
        OnboardingState(
            required: dto.required,
            step: dto.step,
            totalSteps: dto.totalSteps,
            completedAt: dto.completedAt
        )
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

struct CreateSpiritRequest: Equatable, Sendable {
    let clientID: UUID
    let egg: EggType
    let name: String
    let consents: CreateSpiritConsents
}
