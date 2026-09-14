import SwiftUI

struct SocialHostView: View {
    @Bindable var appState: AppState
    @Bindable var router: AppRouter
    @State private var viewModel: SocialViewModel

    init(appState: AppState, router: AppRouter) {
        self.appState = appState
        self.router = router
        _viewModel = State(initialValue: appState.makeSocialViewModel())
    }

    var body: some View {
        SocialView(viewModel: viewModel, onBack: { router.pop() })
            .task { await viewModel.refreshRemote() }
    }
}
