import SwiftUI

struct ReportHostView: View {
    @Bindable var appState: AppState
    @Bindable var router: AppRouter
    @State private var viewModel: ReportViewModel

    init(appState: AppState, router: AppRouter) {
        self.appState = appState
        self.router = router
        _viewModel = State(initialValue: appState.makeReportViewModel())
    }

    var body: some View {
        ReportView(
            viewModel: viewModel,
            onBack: { router.pop() },
            onTalk: { router.push(.chat) }
        )
        .task { await viewModel.refresh() }
    }
}
