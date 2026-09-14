import SwiftUI

struct FeedHostView: View {
    @Bindable var appState: AppState
    @Bindable var router: AppRouter
    @State private var viewModel: FeedViewModel

    init(appState: AppState, router: AppRouter) {
        self.appState = appState
        self.router = router
        _viewModel = State(initialValue: appState.makeFeedViewModel())
    }

    var body: some View {
        FeedView(
            viewModel: viewModel,
            onBack: { router.pop() }
        )
        .task {
            await viewModel.restorePersistedPromise()
        }
        .onChange(of: appState.sessionStore.snapshot?.quotas) { _, quotas in
            viewModel.applySnapshot(
                quotas: quotas ?? [],
                isOffline: appState.isOffline,
                spiritVersion: appState.sessionStore.snapshot?.spirit?.version
            )
        }
        .onChange(of: appState.sessionStore.snapshot?.spirit?.version) { _, version in
            viewModel.applySnapshot(
                quotas: appState.sessionStore.snapshot?.quotas ?? [],
                isOffline: appState.isOffline,
                spiritVersion: version
            )
        }
        .onChange(of: appState.isOffline) { _, offline in
            viewModel.applySnapshot(
                quotas: appState.sessionStore.snapshot?.quotas ?? [],
                isOffline: offline,
                spiritVersion: appState.sessionStore.snapshot?.spirit?.version
            )
        }
    }
}
