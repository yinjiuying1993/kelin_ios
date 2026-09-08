import SwiftData
import XCTest
@testable import Kelin

final class KelinAppShellTests: XCTestCase {
    @MainActor
    func testRootViewCanBeConstructed() {
        let environment = AppEnvironment.preview
        _ = RootView(
            router: AppRouter(),
            appState: environment.makeAppState()
        )
    }
}
