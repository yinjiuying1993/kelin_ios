import SwiftUI
import UIKit

final class KelinAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { @MainActor in
            DeviceTokenCenter.setToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        KelinLog.api.info("device_register_skipped reason=apns_registration_failed")
        _ = error
    }
}

@main
struct KelinApp: App {
    @UIApplicationDelegateAdaptor(KelinAppDelegate.self) private var appDelegate
    @State private var router = AppRouter()
    @State private var appState: AppState

    private let shouldAutoLaunch: Bool

    init() {
        _router = State(initialValue: AppRouter())

        do {
            let environment = try AppEnvironment.makeDefault()
            KelinLog.launch.info(
                "make_default result=ok remote_api=true base=\(environment.apiBaseURL?.absoluteString ?? "nil")"
            )
            _appState = State(initialValue: environment.makeAppState())
            shouldAutoLaunch = true
        } catch {
            KelinLog.launch.error(
                "make_default result=error error_code=APP_CONFIG detail=\(String(describing: error))"
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
                .onReceive(NotificationCenter.default.publisher(for: DeviceTokenCenter.didUpdate)) { _ in
                    Task { await appState.registerDeviceIfPossible() }
                }
        }
    }
}
