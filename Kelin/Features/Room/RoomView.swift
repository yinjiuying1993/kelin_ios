import SwiftUI

struct RoomView: View {
    @Bindable var viewModel: RoomViewModel
    @Bindable var router: AppRouter

    @State private var showMoreMenu = false
    @State private var showPaperNote = false
    @State private var showSightMemory = false
    @State private var selectedMark: RoomMarkKind?
    @State private var recallBlockedMessage: String?
    @State private var crossfadeProgress = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            RoomTopBar(
                subtitle: viewModel.topBarSubtitle,
                onMoreTap: { applyHotspot(.more) }
            )
            .padding(.horizontal, KelinSpacing.pageHorizontal)

            ZStack(alignment: .top) {
                if let outgoingScene = viewModel.outgoingScene {
                    roomSceneStack(for: outgoingScene)
                        .opacity(1 - crossfadeProgress)
                        .allowsHitTesting(false)
                }

                roomSceneStack(for: viewModel.scene)
                    .opacity(viewModel.outgoingScene == nil ? 1 : crossfadeProgress)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: outgoingSceneIdentity) { _, identity in
                guard identity != nil else {
                    crossfadeProgress = 1
                    return
                }
                crossfadeProgress = 0
                if reduceMotion {
                    crossfadeProgress = 1
                } else {
                    withAnimation(.easeInOut(duration: RoomRefreshRules.crossFadeDuration)) {
                        crossfadeProgress = 1
                    }
                }
            }

            VStack(spacing: KelinSpacing.small) {
                if let banner = viewModel.scene.offlineBannerText {
                    Text(banner)
                        .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KelinSpacing.xSmall)
                        .background(KelinColor.surfaceSecondary.opacity(0.85))
                        .clipShape(Capsule())
                }

                Text(viewModel.footerStatusLine)
                    .font(.system(size: 14))
                    .foregroundStyle(KelinColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, KelinSpacing.pageHorizontal)
            .padding(.vertical, KelinSpacing.small)

            RoomDockView(
                primaryAction: viewModel.scene.primaryDockAction,
                onPrimary: { handlePrimaryDockAction(viewModel.scene.primaryDockAction) },
                onFeed: { router.push(.feed) },
                onFootprints: { router.push(.social) }
            )
            .padding(.horizontal, KelinSpacing.pageHorizontal)
            .padding(.bottom, KelinSpacing.standard)

            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 134, height: 5)
                .padding(.bottom, KelinSpacing.small)
        }
        .kelinScreenBackground()
        .kelinConstrainedContentWidth()
        .navigationBarHidden(true)
        .overlay {
            if showMoreMenu {
                RoomMoreMenuSheet(
                    model: viewModel.moreMenu,
                    router: router,
                    onDismiss: { showMoreMenu = false }
                )
                .transition(.identity)
            }
        }
        .sheet(isPresented: $showPaperNote) {
            RoomPaperNoteSheet(letter: viewModel.scene.letter) {
                showPaperNote = false
            }
        }
        .sheet(item: $selectedMark) { kind in
            RoomMarkOriginSheet(kind: kind) {
                selectedMark = nil
            }
        }
        .alert(
            String(localized: "现在还叫不回来"),
            isPresented: Binding(
                get: { recallBlockedMessage != nil },
                set: { if !$0 { recallBlockedMessage = nil } }
            )
        ) {
            Button(String(localized: "好"), role: .cancel) {
                recallBlockedMessage = nil
            }
        } message: {
            Text(recallBlockedMessage ?? "")
        }
        .sheet(isPresented: $showSightMemory) {
            RoomSightMemorySheet(
                onOpenGallery: {
                    showSightMemory = false
                    router.push(.memory)
                },
                onDismiss: { showSightMemory = false }
            )
        }
    }

    private var outgoingSceneIdentity: RoomSceneVisualIdentity? {
        viewModel.outgoingScene.map(RoomRefreshRules.visualIdentity(for:))
    }

    private func roomSceneStack(for scene: RoomSceneModel) -> some View {
        RoomSceneStack(
            scene: scene,
            spiritName: viewModel.spiritName,
            scholarMarks: viewModel.scholarMarks,
            dialogueLine: viewModel.dialogueLine,
            onSpiritTap: { applyHotspot(.spirit) },
            onEyeMarkTap: { applyHotspot(.eyeMark) },
            onScholarRuneTap: { applyHotspot(.scholarRune) },
            onFootprintTap: { applyHotspot(.footprint) },
            onBookshelfTap: { applyHotspot(.bookshelf) },
            onArtifactTap: { applyHotspot(.artifact) },
            onPaperNoteTap: { applyHotspot(.paperNote) }
        )
        .padding(.horizontal, KelinSpacing.pageHorizontal)
    }

    private func applyHotspot(_ hotspot: RoomHotspot) {
        apply(viewModel.action(for: hotspot))
    }

    private func apply(_ action: RoomHotspotAction) {
        switch action {
        case .showSpiritDialogue:
            Task {
                try? await Task.sleep(for: .seconds(RoomHotspotRules.spiritDialogueTimeout))
                viewModel.expireSpiritDialogueIfNeeded()
            }
        case .openChat:
            router.push(.chat)
        case let .showMarkOrigin(kind):
            selectedMark = kind
        case .showPaperNote:
            showPaperNote = true
        case .openSocial:
            router.push(.social)
        case .showSightMemory:
            showSightMemory = true
        case .openPact:
            router.push(.pact)
        case .showMoreMenu:
            showMoreMenu = true
        }
    }

    private func handlePrimaryDockAction(_ action: RoomDockAction) {
        switch action {
        case .chat:
            router.push(.chat)
        case .recall:
            if P16P20ContractManifest.liveHasRecallRoute {
                recallBlockedMessage = String(localized: "找回先等服务端契约对齐，现在不会改成在家。")
            } else {
                recallBlockedMessage = String(localized: "找回接口尚未开通，它仍是走失状态。")
            }
        case .pact:
            router.push(.pact)
        case .social:
            router.push(.social)
        case .history:
            router.push(.memory)
        }
    }
}

private struct RoomTopBar: View {
    let subtitle: String
    let onMoreTap: () -> Void

    var body: some View {
        HStack {
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(KelinColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onMoreTap) {
                Image(systemName: "ellipsis")
                    .font(.system(size: KelinIconSize.standard, weight: .medium))
                    .foregroundStyle(KelinColor.textSecondary)
                    .frame(
                        width: RoomHotspotRules.minimumTouchTarget,
                        height: RoomHotspotRules.minimumTouchTarget
                    )
                    .background(KelinColor.surfaceSecondary.opacity(0.7))
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.06), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(RoomHotspotRules.accessibilityLabel(for: .more))
            .accessibilityHint(RoomHotspotRules.accessibilityHint(for: .more))
        }
    }
}

#if DEBUG
enum RoomPreviewFactory {
    @MainActor
    static func viewModel(
        status: SpiritStatus = .home,
        isOffline: Bool = false
    ) -> RoomViewModel {
        RoomViewModel(
            spirit: previewSpirit(status: status),
            room: previewRoom(status: status),
            isOffline: isOffline
        )
    }

    private static func previewSpirit(status: SpiritStatus) -> Spirit {
        Spirit(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            userID: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
            name: "雾生",
            egg: .warm,
            inviteCode: "ABCD2345",
            traits: TraitValues(closeness: 65, curiosity: 55, sharpness: 35, nocturnal: 40, stubborn: 40),
            vitals: VitalValues(hunger: 80, energy: 80, mood: 60, bond: 0),
            stage: .whelp,
            status: status,
            scholarMarks: ["reader"],
            preferences: SpiritPreferences(
                ttsOn: false,
                pushOn: false,
                visitOn: true,
                dndStart: "23:00",
                dndEnd: "08:00",
                timezone: "Asia/Shanghai",
                defaultCity: nil,
                locationWeatherOn: false,
                remoteSearchOn: true
            ),
            awayUntil: nil,
            studyUntil: nil,
            lastInteractAt: Date(timeIntervalSince1970: 1_700_000_000),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            version: 1
        )
    }

    private static func previewRoom(status: SpiritStatus) -> RoomSnapshot {
        RoomSnapshot(
            weather: "cloudy",
            layers: [
                RoomLayer(key: "bookshelf", variant: "default"),
                RoomLayer(key: "door", variant: "default"),
                RoomLayer(key: "window", variant: "default"),
            ],
            letter: status == .lost ? "room.letter.lost" : nil,
            pendingSightID: nil,
            unreadFootprintCount: status == .home ? 2 : 0,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}

#Preview("房间 home") {
    RoomView(
        viewModel: RoomPreviewFactory.viewModel(status: .home),
        router: AppRouter()
    )
}

#Preview("房间 lost") {
    RoomView(
        viewModel: RoomPreviewFactory.viewModel(status: .lost),
        router: AppRouter()
    )
}
#endif
