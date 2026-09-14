import XCTest
@testable import Kelin

final class PactUILayoutTests: XCTestCase {
    func testLayoutTokensMatchS08Canvas() {
        XCTAssertEqual(PactLayout.headerHeight, 48)
        XCTAssertEqual(PactLayout.cardRadius, 18)
        XCTAssertEqual(PactLayout.themeIconWell, 44)
        XCTAssertEqual(PactLayout.scholarMarkSize, 128)
        XCTAssertEqual(KelinSize.primaryButtonHeight, 52)
        XCTAssertGreaterThanOrEqual(KelinSize.minimumTouchTarget, 44)
    }
}
