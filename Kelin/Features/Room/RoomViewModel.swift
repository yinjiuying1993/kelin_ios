import Foundation

enum RoomSceneUpdateEffect: Equatable, Sendable {
    case unchanged
    case immediate
    case crossfade
}

@MainActor
@Observable
final class RoomViewModel {
    private(set) var scene: RoomSceneModel
    private(set) var outgoingScene: RoomSceneModel?
    private(set) var dialogueLine: String?
    private(set) var spiritName: String
    private(set) var scholarMarks: [String]
    private(set) var moreMenu: RoomMoreMenuModel
    private var spirit: Spirit
    private var cachedWeather: String?
    private var latestMemories: [MemorySummary]
    private var activePact: PactSummary?
    private var report: ReportSnapshot?
    private var spiritTapSession = RoomSpiritTapSession()
    private var crossfadeTask: Task<Void, Never>?
    private var crossfadeGeneration = 0

    init(
        spirit: Spirit,
        room: RoomSnapshot?,
        isOffline: Bool,
        cachedWeather: String? = nil,
        latestMemories: [MemorySummary] = [],
        activePact: PactSummary? = nil,
        report: ReportSnapshot? = nil
    ) {
        let resolvedWeather = cachedWeather ?? room?.weather
        self.spirit = spirit
        self.cachedWeather = resolvedWeather
        self.latestMemories = latestMemories
        self.activePact = activePact
        self.report = report
        spiritName = spirit.name
        scholarMarks = spirit.scholarMarks
        scene = Self.makeScene(
            spirit: spirit,
            room: room,
            cachedWeather: resolvedWeather,
            isOffline: isOffline
        )
        moreMenu = Self.makeMoreMenu(
            spirit: spirit,
            weather: resolvedWeather,
            latestMemories: latestMemories,
            activePact: activePact,
            report: report
        )
    }

    var topBarSubtitle: String {
        scene.statusText
    }

    var footerStatusLine: String {
        switch scene.primaryState {
        case .home:
            RoomHomeStatusLine.make(from: spirit.vitals)
        default:
            scene.statusText
        }
    }

    @discardableResult
    func applySnapshotUpdate(
        spirit: Spirit,
        room: RoomSnapshot?,
        isOffline: Bool,
        animated: Bool,
        latestMemories: [MemorySummary] = [],
        activePact: PactSummary? = nil,
        report: ReportSnapshot? = nil
    ) -> RoomSceneUpdateEffect {
        let nextCachedWeather = room?.weather ?? cachedWeather
        let nextScene = Self.makeScene(
            spirit: spirit,
            room: room,
            cachedWeather: nextCachedWeather,
            isOffline: isOffline
        )
        let nextMenu = Self.makeMoreMenu(
            spirit: spirit,
            weather: nextCachedWeather,
            latestMemories: latestMemories,
            activePact: activePact,
            report: report
        )

        if nextScene == scene && nextMenu == moreMenu {
            return .unchanged
        }

        let shouldCrossFade = animated
            && nextScene != scene
            && RoomRefreshRules.shouldCrossFade(from: scene, to: nextScene)

        self.spirit = spirit
        self.latestMemories = latestMemories
        self.activePact = activePact
        self.report = report
        spiritName = spirit.name
        scholarMarks = spirit.scholarMarks
        moreMenu = nextMenu
        cachedWeather = nextCachedWeather

        if shouldCrossFade {
            beginCrossfade(to: nextScene)
            return .crossfade
        }

        crossfadeTask?.cancel()
        crossfadeTask = nil
        outgoingScene = nil
        scene = nextScene
        return .immediate
    }

    func refresh(spirit: Spirit, room: RoomSnapshot?, isOffline: Bool) {
        _ = applySnapshotUpdate(
            spirit: spirit,
            room: room,
            isOffline: isOffline,
            animated: false,
            latestMemories: latestMemories,
            activePact: activePact,
            report: report
        )
    }

    func action(for hotspot: RoomHotspot) -> RoomHotspotAction {
        if hotspot == .spirit {
            return registerSpiritTap()
        }
        return RoomHotspotRules.action(for: hotspot)
    }

    @discardableResult
    func registerSpiritTap() -> RoomHotspotAction {
        let action = spiritTapSession.registerTap()
        switch action {
        case .showSpiritDialogue:
            dialogueLine = RoomHotspotRules.dialogueLines.randomElement()
        case .openChat:
            dialogueLine = nil
        default:
            break
        }
        return action
    }

    func expireSpiritDialogueIfNeeded() {
        guard spiritTapSession.tapCount == 1 else {
            return
        }
        spiritTapSession.expireIfSingleTap()
        dialogueLine = nil
    }

    private func beginCrossfade(to nextScene: RoomSceneModel) {
        crossfadeTask?.cancel()
        outgoingScene = scene
        scene = nextScene

        crossfadeGeneration += 1
        let generation = crossfadeGeneration
        crossfadeTask = Task { [weak self] in
            let duration = RoomRefreshRules.crossFadeDuration
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.crossfadeGeneration == generation else { return }
                self.outgoingScene = nil
                self.crossfadeTask = nil
            }
        }
    }

    private static func makeScene(
        spirit: Spirit,
        room: RoomSnapshot?,
        cachedWeather: String?,
        isOffline: Bool
    ) -> RoomSceneModel {
        RoomRules.makeScene(
            from: RoomRulesInput(
                spirit: spirit,
                room: room,
                cachedWeather: cachedWeather,
                isOffline: isOffline
            )
        )
    }

    private static func makeMoreMenu(
        spirit: Spirit,
        weather: String?,
        latestMemories: [MemorySummary],
        activePact: PactSummary?,
        report: ReportSnapshot?
    ) -> RoomMoreMenuModel {
        RoomMoreMenuRules.make(
            spirit: spirit,
            weather: RoomRules.mapWeather(raw: weather, fallback: nil),
            latestMemories: latestMemories,
            activePact: activePact,
            report: report
        )
    }
}

enum RoomHomeStatusLine {
    static func make(from vitals: VitalValues) -> String {
        if vitals.hunger < 55 {
            return String(localized: "有点饿 · 想说话")
        }
        if vitals.mood < 45 {
            return String(localized: "有点闷 · 想说话")
        }
        return String(localized: "有点饿 · 想说话")
    }
}
