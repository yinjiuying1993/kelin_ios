import Foundation

actor MockAgreementGateService: AgreementGateServiceProtocol {
    struct Configuration: Sendable {
        var error: AppError?
        var delay: Duration?

        static let success = Configuration()
    }

    private var configuration: Configuration
    private(set) var attemptCount = 0

    init(configuration: Configuration = .success) {
        self.configuration = configuration
    }

    func setConfiguration(_ configuration: Configuration) {
        self.configuration = configuration
    }

    func attemptCountValue() -> Int {
        attemptCount
    }

    func acknowledgeAgreement(consents: CreateSpiritConsents) async throws {
        attemptCount += 1
        if let delay = configuration.delay {
            try await Task.sleep(for: delay)
        }

        try Task.checkCancellation()

        guard consents.aiDisclosure.explicitlyAccepted else {
            throw AppError.invalidInput
        }

        if let error = configuration.error {
            throw error
        }
    }
}
