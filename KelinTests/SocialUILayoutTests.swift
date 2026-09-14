import XCTest
@testable import Kelin

final class SocialUILayoutTests: XCTestCase {
    func testLayoutTokensMatchS09Canvas() {
        XCTAssertEqual(SocialLayout.headerHeight, 48)
        XCTAssertEqual(SocialLayout.cardRadius, 24)
        XCTAssertEqual(SocialLayout.rowRadius, 18)
        XCTAssertEqual(SocialLayout.avatarWell, 40)
        XCTAssertEqual(SocialLayout.unreadDot, 8)
        XCTAssertEqual(SocialLayout.postcardArtHeight, 144)
        XCTAssertEqual(KelinSize.primaryButtonHeight, 52)
        XCTAssertGreaterThanOrEqual(KelinSize.minimumTouchTarget, 44)
    }
}
