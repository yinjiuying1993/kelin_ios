import Foundation

struct RegisterDeviceRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let installationID: UUID
    let apnsToken: String
    let environment: String
    let enabled: Bool
    let appVersion: String?
    let locale: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case installationID = "installation_id"
        case apnsToken = "apns_token"
        case environment
        case enabled
        case appVersion = "app_version"
        case locale
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clientID, forKey: .clientID)
        try container.encode(installationID, forKey: .installationID)
        try container.encode(apnsToken, forKey: .apnsToken)
        try container.encode(environment, forKey: .environment)
        try container.encode(enabled, forKey: .enabled)
        try container.encodeIfPresent(appVersion, forKey: .appVersion)
        try container.encodeIfPresent(locale, forKey: .locale)
    }
}

struct DeviceRegistrationDTO: Decodable, Sendable, Equatable {
    let deviceID: UUID
    let enabled: Bool
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case enabled
        case updatedAt = "updated_at"
        case apnsToken = "apns_token"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.apnsToken) {
            throw DecodingError.dataCorruptedError(
                forKey: .apnsToken,
                in: container,
                debugDescription: "device response must not include apns_token"
            )
        }
        try MemoryDTOCoding.rejectUnknownKeys(
            in: container,
            allowed: Set(P16P20ContractManifest.deviceResponseFields),
            debugDescription: "DeviceRegistration extra fields"
        )
        deviceID = try container.decode(UUID.self, forKey: .deviceID)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
