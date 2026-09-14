import XCTest
@testable import Kelin

final class SettingsUILayoutTests: XCTestCase {
    func testLayoutTokensMatchS11Canvas() {
        XCTAssertEqual(SettingsLayout.headerHeight, 48)
        XCTAssertEqual(SettingsLayout.rowHeight, 52)
        XCTAssertEqual(SettingsLayout.groupRadius, 18)
        XCTAssertEqual(KelinSize.settingsRowHeight, SettingsLayout.rowHeight)
        XCTAssertGreaterThanOrEqual(KelinSize.minimumTouchTarget, 44)
    }
}
