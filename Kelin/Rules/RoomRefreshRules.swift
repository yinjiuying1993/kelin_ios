import Foundation

struct RoomSceneVisualIdentity: Equatable, Sendable {
    let primaryState: SpiritStatus
    let weather: RoomWeather
    let layers: [RoomLayerPresentation]
    let title: String
    let statusText: String
    let letter: RoomLetter?
    let unreadFootprints: Int
    let pendingSight: PendingSightPresentation?
    let spiritVisible: Bool
    let dimmingFactor: Double
}

enum RoomRefreshRules {
    static let crossFadeDuration: TimeInterval = 0.35
    static let foregroundRefreshInterval: TimeInterval = 5 * 60

    static func visualIdentity(for scene: RoomSceneModel) -> RoomSceneVisualIdentity {
        RoomSceneVisualIdentity(
            primaryState: scene.primaryState,
            weather: scene.weather,
            layers: scene.layers,
            title: scene.title,
            statusText: scene.statusText,
            letter: scene.letter,
            unreadFootprints: scene.unreadFootprints,
            pendingSight: scene.pendingSight,
            spiritVisible: scene.spiritVisible,
            dimmingFactor: scene.dimmingFactor
        )
    }

    static func shouldCrossFade(from oldScene: RoomSceneModel, to newScene: RoomSceneModel) -> Bool {
        visualIdentity(for: oldScene) != visualIdentity(for: newScene)
    }

    static func shouldRefresh(lastRefreshAt: Date?, now: Date) -> Bool {
        guard let lastRefreshAt else {
            return true
        }
        return now.timeIntervalSince(lastRefreshAt) >= foregroundRefreshInterval
    }
}
