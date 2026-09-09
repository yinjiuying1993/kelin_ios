import Foundation

protocol AgreementGateServiceProtocol: Sendable {
    func acknowledgeAgreement(consents: CreateSpiritConsents) async throws
}
