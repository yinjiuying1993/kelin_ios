import SwiftUI

@main
struct KelinApp: App {
    @State private var environment = AppEnvironment()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView(router: router)
                .environment(environment)
        }
    }
}
