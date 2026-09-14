import SwiftUI

struct MemoryHostView: View {
    @Bindable var appState: AppState
    @Bindable var router: AppRouter
    @State private var viewModel: MemoryViewModel

    init(appState: AppState, router: AppRouter) {
        self.appState = appState
        self.router = router
        _viewModel = State(initialValue: appState.makeMemoryViewModel())
    }

    var body: some View {
        MemoryView(
            viewModel: viewModel,
            onBack: { router.pop() },
            onTalk: { router.path = [.chat] }
        )
        .task {
            await viewModel.loadInitial()
        }
        .onChange(of: appState.sessionStore.snapshot?.spirit?.name) { _, name in
            viewModel.applySnapshotUpdate(
                spiritName: name ?? viewModel.spiritName,
                isOffline: appState.isOffline
            )
        }
        .onChange(of: appState.isOffline) { _, offline in
            viewModel.applySnapshotUpdate(
                spiritName: viewModel.spiritName,
                isOffline: offline
            )
        }
    }
}
