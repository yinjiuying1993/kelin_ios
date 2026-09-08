import SwiftUI

@main
struct KelinApp: App {
    @State private var router = AppRouter()
    @State private var appState: AppState

    init() {
        let environment = (try? AppEnvironment.makeDefault())
            ?? AppEnvironment.preview
        _router = State(initialValue: AppRouter())
        _appState = State(initialValue: environment.makeAppState())
    }

    var body: some Scene {
        WindowGroup {
            RootView(router: router, appState: appState)
                .task {
                    appState.beginLaunch()
                }
        }
    }
}
