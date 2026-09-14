import Foundation

enum ChatMapper {
    static func makeRequest(
        clientMessageID: UUID,
        content: String
    ) -> ChatRequestDTO {
        makeRequest(
            clientMessageID: clientMessageID,
            content: content,
            context: ChatSendContext.make(weather: "cloudy"),
            onboarding: true,
            source: "onboarding"
        )
    }

    static func makeRequest(
        clientMessageID: UUID,
        content: String,
        context: ChatSendContext,
        onboarding: Bool,
        source: String = "text"
    ) -> ChatRequestDTO {
        ChatRequestDTO(
            clientMessageID: clientMessageID,
            content: content,
            source: source,
            onboarding: onboarding,
            context: ChatContextDTO(
                timezone: context.timezone,
                localHour: context.localHour,
                weather: context.weather,
                city: context.city
            )
        )
    }

    static func mapChatTurnResult(_ dto: ChatMutationResultDTO, serverTime: Date) throws -> ChatTurnResult {
        guard dto.resource.type == "chat_turn" else {
            throw AppError.decoding
        }

        let patch = try SessionPatchMapper.attachingQuotas(
            try SessionPatchMapper.map(dto.patch, serverTime: serverTime),
            from: dto.quotas
        )

        return ChatTurnResult(
            userMessage: ChatMessage(
                id: dto.resource.userMessage.id,
                clientID: dto.resource.userMessage.clientID ?? dto.resource.userMessage.id,
                role: .user,
                content: dto.resource.userMessage.content,
                source: .text,
                status: .accepted,
                createdAt: serverTime
            ),
            spiritMessage: ChatMessage(
                id: dto.resource.spiritMessage.id,
                clientID: dto.resource.spiritMessage.clientID ?? dto.resource.spiritMessage.id,
                role: .spirit,
                content: dto.resource.spiritMessage.content,
                source: .text,
                status: .generated,
                sourceRefs: dto.resource.spiritMessage.sourceRefs.map(MessagesMapper.mapSourceRef),
                createdAt: serverTime
            ),
            conversationWindowID: dto.resource.conversationWindowID,
            shouldExtract: dto.resource.shouldExtract,
            usesStubProvider: dto.resource.generationSource == "stub",
            patch: patch
        )
    }

    static func mapOnboardingChatResult(_ dto: ChatMutationResultDTO) throws -> OnboardingChatResult {
        guard dto.resource.type == "chat_turn" else {
            throw AppError.decoding
        }

        guard let onboardingDTO = dto.patch.onboarding else {
            throw AppError.decoding
        }

        let spirit: Spirit?
        if let spiritDTO = dto.patch.spirit {
            spirit = try SpiritMapper.mapSpirit(
                spiritDTO,
                preferences: dto.patch.preferences ?? spiritDTO.preferences ?? defaultPreferences()
            )
        } else {
            spirit = nil
        }

        return OnboardingChatResult(
            userMessage: OnboardingMessage(
                id: dto.resource.userMessage.id,
                role: .user,
                text: dto.resource.userMessage.content
            ),
            spiritMessage: OnboardingMessage(
                id: dto.resource.spiritMessage.id,
                role: .spirit,
                text: dto.resource.spiritMessage.content
            ),
            completedRounds: onboardingDTO.step,
            snapshotVersion: dto.patch.snapshotVersion,
            usesStubProvider: dto.resource.generationSource == "stub",
            spirit: spirit
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
