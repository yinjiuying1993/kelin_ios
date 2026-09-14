import Foundation

enum RoomRules {
    static func makeScene(from input: RoomRulesInput) -> RoomSceneModel {
        let primaryState = resolvePrimaryState(input.spirit.status)
        let weather = mapWeather(
            raw: input.room?.weather,
            fallback: input.cachedWeather
        )
        let unreadFootprints = input.room?.unreadFootprintCount ?? 0
        let layers = mapLayers(input.room?.layers ?? [])

        return RoomSceneModel(
            primaryState: primaryState,
            isOffline: input.isOffline,
            weather: weather,
            layers: layers,
            title: title(for: primaryState, spiritName: input.spirit.name),
            statusText: statusText(
                for: primaryState,
                weather: weather,
                unreadFootprints: unreadFootprints
            ),
            offlineBannerText: input.isOffline ? offlineBannerText : nil,
            letter: mapLetter(input.room?.letter),
            unreadFootprints: unreadFootprints,
            pendingSight: mapPendingSight(input.room?.pendingSightID),
            spiritVisible: spiritVisible(for: primaryState),
            dimmingFactor: dimmingFactor(for: primaryState),
            primaryDockAction: primaryDockAction(for: primaryState, isOffline: input.isOffline)
        )
    }

    static func resolvePrimaryState(_ status: SpiritStatus) -> SpiritStatus {
        status
    }

    static func resolvePrimaryState(from candidates: [SpiritStatus]) -> SpiritStatus {
        let priority: [SpiritStatus] = [.lost, .study, .away, .home]
        for state in priority where candidates.contains(state) {
            return state
        }
        return candidates.first ?? .home
    }

    static func mapWeather(raw: String?, fallback: String?) -> RoomWeather {
        if let raw, let weather = RoomWeather(rawValue: raw.lowercased()) {
            return weather
        }
        if let fallback, let weather = RoomWeather(rawValue: fallback.lowercased()) {
            return weather
        }
        return .cloudy
    }

    static func mapLayers(_ layers: [RoomLayer]) -> [RoomLayerPresentation] {
        layers
            .filter { isKnownProjectionToken($0.key) }
            .map { layer in
                RoomLayerPresentation(
                    key: layer.key,
                    variant: normalizedVariant(layer.variant),
                    assetName: assetName(for: layer),
                    zIndex: zIndex(for: layer.key)
                )
            }
            .sorted { $0.zIndex < $1.zIndex }
    }

    static func mapLetter(_ titleKey: String?) -> RoomLetter? {
        guard let titleKey, !titleKey.isEmpty else {
            return nil
        }

        return RoomLetter(
            titleKey: titleKey,
            displayTitle: localizedLetterTitle(for: titleKey)
        )
    }

    static func mapPendingSight(_ id: UUID?) -> PendingSightPresentation? {
        guard let id else {
            return nil
        }

        return PendingSightPresentation(
            id: id,
            assetName: "prop_pending_sight"
        )
    }

    private static func title(for state: SpiritStatus, spiritName: String) -> String {
        switch state {
        case .home:
            spiritName
        case .study:
            String(localized: "它出去学了")
        case .away:
            String(localized: "它去了朋友家")
        case .lost:
            String(localized: "它不在")
        }
    }

    private static func statusText(
        for state: SpiritStatus,
        weather: RoomWeather,
        unreadFootprints: Int
    ) -> String {
        switch state {
        case .home:
            if unreadFootprints > 0 {
                return "\(weather.displayName) · \(String(localized: "门口有足迹"))"
            }
            return weather.displayName
        case .study:
            return String(localized: "它出去学了")
        case .away:
            return String(localized: "它去了朋友家")
        case .lost:
            return String(localized: "房间里还留着一点温度")
        }
    }

    private static var offlineBannerText: String {
        String(localized: "连不上，房间还在")
    }

    private static func spiritVisible(for state: SpiritStatus) -> Bool {
        state == .home
    }

    private static func dimmingFactor(for state: SpiritStatus) -> Double {
        state == .lost ? 0.82 : 1.0
    }

    private static func primaryDockAction(
        for state: SpiritStatus,
        isOffline: Bool
    ) -> RoomDockAction {
        if isOffline {
            return .history
        }

        switch state {
        case .home:
            return .chat
        case .study:
            return .pact
        case .away:
            return .social
        case .lost:
            return .recall
        }
    }

    private static let knownProjectionTokens: Set<String> = [
        "floor",
        "furniture",
        "bookshelf",
        "window",
        "door",
        "trait_mark",
        "scholar_mark",
        "scholar",
        "spirit",
        "pending_sight",
    ]

    private static func isKnownProjectionToken(_ key: String) -> Bool {
        knownProjectionTokens.contains(key)
    }

    private static func assetName(for layer: RoomLayer) -> String {
        "room_\(layer.key)_\(normalizedVariant(layer.variant))"
    }

    private static func normalizedVariant(_ variant: String) -> String {
        variant.isEmpty ? "default" : variant
    }

    private static func zIndex(for key: String) -> Int {
        switch key {
        case "floor":
            10
        case "furniture":
            20
        case "bookshelf":
            30
        case "window":
            40
        case "door":
            50
        case "spirit":
            55
        case "trait_mark":
            60
        case "scholar", "scholar_mark":
            70
        case "pending_sight":
            80
        default:
            25
        }
    }

    private static func localizedLetterTitle(for titleKey: String) -> String {
        switch titleKey {
        case "room.letter.lost":
            String(localized: "我想起那盏坏掉的灯。")
        case "room.letter.pact":
            String(localized: "今天的约定")
        case "room.letter.visit":
            String(localized: "有客来过")
        case "room.letter.care":
            String(localized: "它想你了")
        case "room.letter.promise":
            String(localized: "约定到了")
        default:
            titleKey
        }
    }
}
