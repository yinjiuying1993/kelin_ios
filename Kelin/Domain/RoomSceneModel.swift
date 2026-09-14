import Foundation

enum RoomWeather: String, Equatable, Sendable, Codable {
    case cloudy
    case rain
    case clear
    case snow
    case unknown

    var displayName: String {
        switch self {
        case .cloudy:
            String(localized: "阴天")
        case .rain:
            String(localized: "雨天")
        case .clear:
            String(localized: "晴天")
        case .snow:
            String(localized: "雪天")
        case .unknown:
            String(localized: "阴天")
        }
    }
}

enum RoomDockAction: String, Equatable, Sendable, Codable {
    case chat
    case pact
    case social
    case recall
    case history
}

struct RoomLayerPresentation: Equatable, Sendable, Codable {
    let key: String
    let variant: String
    let assetName: String
    let zIndex: Int
}

struct RoomLetter: Equatable, Sendable, Codable {
    let titleKey: String
    let displayTitle: String
}

struct PendingSightPresentation: Equatable, Sendable, Codable {
    let id: UUID
    let assetName: String
}

struct RoomSceneModel: Equatable, Sendable {
    let primaryState: SpiritStatus
    let isOffline: Bool
    let weather: RoomWeather
    let layers: [RoomLayerPresentation]
    let title: String
    let statusText: String
    let offlineBannerText: String?
    let letter: RoomLetter?
    let unreadFootprints: Int
    let pendingSight: PendingSightPresentation?
    let spiritVisible: Bool
    let dimmingFactor: Double
    let primaryDockAction: RoomDockAction
}

struct RoomRulesInput: Equatable, Sendable {
    let spirit: Spirit
    let room: RoomSnapshot?
    let cachedWeather: String?
    let isOffline: Bool
}
