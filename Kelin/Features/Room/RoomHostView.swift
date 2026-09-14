import SwiftUI

struct RoomHostView: View {
    @Bindable var appState: AppState
    @Bindable var router: AppRouter

    let spirit: Spirit
    let room: RoomSnapshot?

    @State private var viewModel: RoomViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        appState: AppState,
        router: AppRouter,
        spirit: Spirit,
        room: RoomSnapshot?
    ) {
        self.appState = appState
        self.router = router
        self.spirit = spirit
        self.room = room
        _viewModel = State(
            initialValue: RoomViewModel(
                spirit: spirit,
                room: room,
                isOffline: appState.isOffline,
                cachedWeather: room?.weather,
                latestMemories: appState.sessionStore.snapshot?.latestMemories ?? [],
                activePact: appState.sessionStore.snapshot?.activePact,
                report: appState.sessionStore.snapshot?.report
            )
        )
    }

    var body: some View {
        RoomView(viewModel: viewModel, router: router)
            .onChange(of: refreshToken) { _, _ in
                viewModel.applySnapshotUpdate(
                    spirit: spirit,
                    room: room,
                    isOffline: appState.isOffline,
                    animated: !reduceMotion,
                    latestMemories: appState.sessionStore.snapshot?.latestMemories ?? [],
                    activePact: appState.sessionStore.snapshot?.activePact,
                    report: appState.sessionStore.snapshot?.report
                )
            }
    }

    private var refreshToken: RoomRefreshToken {
        RoomRefreshToken(
            snapshotVersion: appState.sessionStore.snapshot?.snapshotVersion ?? 0,
            spiritVersion: spirit.version,
            spiritStatus: spirit.status,
            roomUpdatedAt: room?.updatedAt,
            isOffline: appState.isOffline
        )
    }
}

private struct RoomRefreshToken: Equatable {
    let snapshotVersion: Int
    let spiritVersion: Int
    let spiritStatus: SpiritStatus
    let roomUpdatedAt: Date?
    let isOffline: Bool
}
