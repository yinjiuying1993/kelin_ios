import Foundation

actor MockHatchService: HatchServiceProtocol {
    enum Mode: Sendable {
        case success(EggType)
        case businessError(AppError)
    }

    private var mode: Mode = .success(.warm)
    private(set) var requests: [CreateSpiritRequest] = []

    func setMode(_ mode: Mode) {
        self.mode = mode
    }

    func recordedRequests() -> [CreateSpiritRequest] {
        requests
    }

    func createSpirit(_ request: CreateSpiritRequest) async throws -> CreateSpiritResult {
        requests.append(request)

        switch mode {
        case let .success(egg):
            return Self.makeSuccess(for: request, egg: egg)
        case let .businessError(error):
            throw error
        }
    }

    private static func makeSuccess(
        for request: CreateSpiritRequest,
        egg: EggType
    ) -> CreateSpiritResult {
        let traits = initialTraits(for: egg)
        let timestamp = Date(timeIntervalSince1970: 1_700_010_000)
        let spiritID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!

        let spirit = Spirit(
            id: spiritID,
            userID: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
            name: request.name,
            egg: egg,
            inviteCode: "ABCD2345",
            traits: traits,
            vitals: VitalValues(hunger: 80, energy: 80, mood: 60, bond: 0),
            stage: .whelp,
            status: .home,
            scholarMarks: [],
            preferences: SpiritPreferences(
                ttsOn: false,
                pushOn: false,
                visitOn: true,
                dndStart: "23:00",
                dndEnd: "08:00",
                timezone: "Asia/Shanghai",
                defaultCity: nil,
                locationWeatherOn: false,
                remoteSearchOn: true
            ),
            awayUntil: nil,
            studyUntil: nil,
            lastInteractAt: timestamp,
            createdAt: timestamp,
            updatedAt: timestamp,
            version: 1
        )

        return CreateSpiritResult(
            spirit: spirit,
            onboarding: OnboardingState(
                required: true,
                step: 0,
                totalSteps: 5,
                completedAt: nil
            ),
            snapshotVersion: 1
        )
    }

    private static func initialTraits(for egg: EggType) -> TraitValues {
        switch egg {
        case .warm:
            TraitValues(closeness: 65, curiosity: 55, sharpness: 35, nocturnal: 40, stubborn: 40)
        case .cold:
            TraitValues(closeness: 35, curiosity: 45, sharpness: 70, nocturnal: 60, stubborn: 55)
        case .wild:
            TraitValues(closeness: 50, curiosity: 50, sharpness: 50, nocturnal: 50, stubborn: 50)
        }
    }
}
