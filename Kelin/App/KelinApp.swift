import SwiftUI

@main
struct KelinApp: App {
    @State private var environment = AppEnvironment()
    @State private var router = AppRouter()
    @State private var appState: AppState

    init() {
        let environment = AppEnvironment()
        _environment = State(initialValue: environment)
        _router = State(initialValue: AppRouter())
        _appState = State(initialValue: AppState(auth: environment.auth))
    }

    var body: some Scene {
        WindowGroup {
            RootView(router: router, appState: appState)
                .environment(environment)
                .task {
                    appState.beginLaunch()
                }
        }
    }
}
