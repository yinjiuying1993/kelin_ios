import Foundation

enum ChatMapper {
    static func makeRequest(
        clientMessageID: UUID,
        content: String
    ) -> ChatRequestDTO {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        return ChatRequestDTO(
            clientMessageID: clientMessageID,
            content: content,
            source: "text",
            onboarding: true,
            context: ChatContextDTO(
                timezone: TimeZone.current.identifier,
                localHour: hour,
                weather: "unknown",
                city: nil
            )
        )
    }

    static func mapOnboardingChatResult(_ dto: ChatMutationResultDTO) throws -> OnboardingChatResult {
        guard dto.resource.type == "chat_turn" else {
            throw AppError.decoding
        }

        guard let onboardingDTO = dto.patch.onboarding else {
            throw AppError.decoding
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
            usesStubProvider: dto.resource.generationSource == "stub"
        )
    }
}
