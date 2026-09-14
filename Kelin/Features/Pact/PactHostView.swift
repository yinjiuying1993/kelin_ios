import SwiftUI

struct PactHostView: View {
    @Bindable var appState: AppState
    @Bindable var router: AppRouter
    @State private var viewModel: PactViewModel

    init(appState: AppState, router: AppRouter) {
        self.appState = appState
        self.router = router
        _viewModel = State(initialValue: appState.makePactViewModel())
    }

    var body: some View {
        PactView(viewModel: viewModel, onBack: { router.pop() })
            .task {
                await viewModel.restoreQueueIfNeeded()
            }
    }
}
