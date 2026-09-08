import Foundation

actor MockBootstrapService: BootstrapServiceProtocol {
    enum Mode: Sendable {
        case fullUser
        case onboardingUser
        case newUser
        case snapshot(BootstrapSnapshot)
        case failure(AppError)
    }

    private var mode: Mode
    private var delay: Duration?
    private(set) var fetchCount = 0

    init(mode: Mode = .fullUser, delay: Duration? = nil) {
        self.mode = mode
        self.delay = delay
    }

    func setMode(_ mode: Mode) {
        self.mode = mode
    }

    func setDelay(_ delay: Duration?) {
        self.delay = delay
    }

    func fetchCountValue() -> Int {
        fetchCount
    }

    func fetchBootstrap() async throws -> BootstrapSnapshot {
        fetchCount += 1

        if let delay {
            try await Task.sleep(for: delay)
        }

        try Task.checkCancellation()

        switch mode {
        case .fullUser:
            return try Self.decodeFixture(BootstrapDraftFixtures.fullUserEnvelope)
        case .onboardingUser:
            return try Self.decodeFixture(BootstrapDraftFixtures.onboardingUserEnvelope)
        case .newUser:
            return try Self.decodeFixture(BootstrapDraftFixtures.newUserEnvelope)
        case let .snapshot(snapshot):
            return snapshot
        case let .failure(error):
            throw error
        }
    }

    private static func decodeFixture(_ json: String) throws -> BootstrapSnapshot {
        let envelope: APIEnvelope<BootstrapDataDTO> = try APIDecoding.makeJSONDecoder().decode(
            APIEnvelope<BootstrapDataDTO>.self,
            from: Data(json.utf8)
        )
        guard let data = envelope.data else {
            throw AppError.decoding
        }
        return try BootstrapMapper.map(data, serverTime: envelope.serverTime)
    }
}
