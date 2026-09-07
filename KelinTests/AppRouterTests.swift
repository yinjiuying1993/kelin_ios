import XCTest
@testable import Kelin

@MainActor
final class AppRouterTests: XCTestCase {
    func testPushingAndPoppingARouteResetsTheStack() {
        let router = AppRouter()

        router.push(.chat)

        XCTAssertEqual(router.path, [.chat])

        router.pop()

        XCTAssertTrue(router.path.isEmpty)
    }

    func testPresentingAndDismissingASheetResetsTheSheet() {
        let router = AppRouter()

        router.present(.renameSpirit)

        XCTAssertEqual(router.sheet, .renameSpirit)

        router.dismissSheet()

        XCTAssertNil(router.sheet)
    }

    func testResetClearsPathAndSheet() {
        let router = AppRouter()
        router.push(.settings)
        router.present(.addFriend)

        router.reset()

        XCTAssertTrue(router.path.isEmpty)
        XCTAssertNil(router.sheet)
    }

    func testDebugRouteExistsOnlyInDebugBuilds() {
        #if DEBUG
        XCTAssertTrue(Route.includesDebugRoute)
        routerCanPushDebugRoute()
        #else
        XCTAssertFalse(Route.includesDebugRoute)
        #endif
    }

    func testPreviewEnvironmentIsNotASharedSingleton() {
        let first = AppEnvironment.preview
        let second = AppEnvironment.preview

        XCTAssertFalse(first === second)
    }

    func testRootViewCanBeConstructedWithInjectedDependencies() {
        _ = RootView(router: AppRouter())
            .environment(AppEnvironment.preview)
    }

    #if DEBUG
    private func routerCanPushDebugRoute() {
        let router = AppRouter()
        router.push(.debug)
        XCTAssertEqual(router.path, [.debug])
    }
    #endif
}
