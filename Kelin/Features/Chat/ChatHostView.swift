import SwiftUI

struct ChatHostView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: ChatViewModel?

    var body: some View {
        Group {
            if let viewModel, let spirit = appState.sessionStore.snapshot?.spirit {
                ChatView(
                    viewModel: viewModel,
                    spiritName: spirit.name,
                    isOffline: appState.isOffline,
                    onBack: { dismiss() }
                )
            } else {
                ProgressView()
                    .kelinScreenBackground()
            }
        }
        .task {
            guard viewModel == nil else { return }
            guard let model = appState.makeChatViewModel() else { return }
            viewModel = model
            try? await model.restore()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                viewModel?.handleSceneBackground()
            }
        }
    }
}
