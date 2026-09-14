import Foundation

struct PreferencesPatchDTO: Encodable, Sendable, Equatable {
    var ttsOn: Bool?
    var pushOn: Bool?
    var visitOn: Bool?
    var dndStart: String?
    var dndEnd: String?
    var timezone: String?
    var defaultCity: String?
    var clearDefaultCity = false
    var locationWeatherOn: Bool?
    var remoteSearchOn: Bool?

    enum CodingKeys: String, CodingKey {
        case ttsOn = "tts_on"
        case pushOn = "push_on"
        case visitOn = "visit_on"
        case dndStart = "dnd_start"
        case dndEnd = "dnd_end"
        case timezone
        case defaultCity = "default_city"
        case locationWeatherOn = "location_weather_on"
        case remoteSearchOn = "remote_search_on"
    }

    var hasField: Bool {
        ttsOn != nil
            || pushOn != nil
            || visitOn != nil
            || dndStart != nil
            || dndEnd != nil
            || timezone != nil
            || clearDefaultCity
            || defaultCity != nil
            || locationWeatherOn != nil
            || remoteSearchOn != nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(ttsOn, forKey: .ttsOn)
        try container.encodeIfPresent(pushOn, forKey: .pushOn)
        try container.encodeIfPresent(visitOn, forKey: .visitOn)
        try container.encodeIfPresent(dndStart, forKey: .dndStart)
        try container.encodeIfPresent(dndEnd, forKey: .dndEnd)
        try container.encodeIfPresent(timezone, forKey: .timezone)
        if clearDefaultCity {
            try container.encodeNil(forKey: .defaultCity)
        } else {
            try container.encodeIfPresent(defaultCity, forKey: .defaultCity)
        }
        try container.encodeIfPresent(locationWeatherOn, forKey: .locationWeatherOn)
        try container.encodeIfPresent(remoteSearchOn, forKey: .remoteSearchOn)
    }
}

struct PatchSpiritRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let expectedVersion: Int
    let name: String?
    let preferences: PreferencesPatchDTO?

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case expectedVersion = "expected_version"
        case name
        case preferences
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clientID, forKey: .clientID)
        try container.encode(expectedVersion, forKey: .expectedVersion)
        try container.encodeIfPresent(name, forKey: .name)
        if let preferences, preferences.hasField {
            try container.encode(preferences, forKey: .preferences)
        }
    }
}

struct SpiritPatchResultDTO: Decodable, Sendable, Equatable {
    let resource: MutationResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
}

struct DeleteAccountRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let confirm: String

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case confirm
    }
}

struct AccountDeletionDTO: Decodable, Sendable, Equatable {
    let deletionID: UUID
    let status: String
    let requestedAt: Date

    enum CodingKeys: String, CodingKey {
        case deletionID = "deletion_id"
        case status
        case requestedAt = "requested_at"
    }
}
