import Foundation

enum OnboardingCompleteMapper {
    static func map(_ dto: MutationResultDTO) throws -> OnboardingCompleteResult {
        guard let onboardingDTO = dto.patch.onboarding else {
            throw AppError.decoding
        }

        return OnboardingCompleteResult(
            onboarding: BootstrapMapper.mapOnboarding(onboardingDTO),
            room: dto.patch.room.map(BootstrapMapper.mapRoom),
            snapshotVersion: dto.patch.snapshotVersion
        )
    }
}
