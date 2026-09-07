import XCTest
@testable import Kelin

final class KelinAppShellTests: XCTestCase {
    @MainActor
    func testRootViewCanBeConstructed() {
        _ = RootView(router: AppRouter())
            .environment(AppEnvironment.preview)
    }
}
