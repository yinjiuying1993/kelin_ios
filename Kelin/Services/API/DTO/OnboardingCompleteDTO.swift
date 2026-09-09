import Foundation

struct OnboardingCompleteRequestDTO: Codable, Sendable, Equatable {
    let clientID: UUID
    let expectedSpiritVersion: Int

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case expectedSpiritVersion = "expected_spirit_version"
    }
}
