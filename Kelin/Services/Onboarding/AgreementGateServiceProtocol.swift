import Foundation

protocol AgreementGateServiceProtocol: Sendable {
    func acknowledgeAgreement(consents: CreateSpiritConsents) async throws
}

actor LocalAgreementGateService: AgreementGateServiceProtocol {
    func acknowledgeAgreement(consents: CreateSpiritConsents) async throws {
        guard consents.aiDisclosure.explicitlyAccepted else {
            throw AppError.invalidInput
        }
    }
}
