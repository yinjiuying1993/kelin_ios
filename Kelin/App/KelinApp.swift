import SwiftUI

@main
struct KelinApp: App {
    @State private var router = AppRouter()
    @State private var appState: AppState

    private let shouldAutoLaunch: Bool

    init() {
        _router = State(initialValue: AppRouter())

        do {
            let environment = try AppEnvironment.makeDefault()
            KelinLog.launch.info(
                "make_default result=ok remote_api=true base=\(environment.apiBaseURL?.absoluteString ?? "nil", privacy: .public)"
            )
            _appState = State(initialValue: environment.makeAppState())
            shouldAutoLaunch = true
        } catch {
            KelinLog.launch.error(
                "make_default result=error error_code=APP_CONFIG detail=\(String(describing: error), privacy: .public)"
            )
            let fallback = AppEnvironment.preview
            let state = fallback.makeAppState()
            state.failBeforeLaunch(.unknown(requestID: "app-config"))
            _appState = State(initialValue: state)
            shouldAutoLaunch = false
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(router: router, appState: appState)
                .task {
                    guard shouldAutoLaunch else { return }
                    appState.beginLaunch()
                }
        }
    }
}
