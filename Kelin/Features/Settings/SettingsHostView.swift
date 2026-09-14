import SwiftUI

struct SettingsHostView: View {
    @Bindable var appState: AppState
    @Bindable var router: AppRouter
    @State private var viewModel: SettingsViewModel

    init(appState: AppState, router: AppRouter) {
        self.appState = appState
        self.router = router
        _viewModel = State(initialValue: appState.makeSettingsViewModel())
    }

    var body: some View {
        SettingsView(
            viewModel: viewModel,
            onBack: { router.pop() },
            onFriends: { router.push(.social) },
            onMemory: { router.push(.memory) }
        )
        .task { await viewModel.refreshFriendCount() }
    }
}
