import SwiftUI
import UIKit
import XCTest
@testable import Kelin

final class DesignTokensTests: XCTestCase {
    func testColorTokensMatchVisualSpecification() {
        assertColor(KelinColor.backgroundBase, hex: 0x10131B)
        assertColor(KelinColor.surfacePrimary, hex: 0x181D2A)
        assertColor(KelinColor.textPrimary, hex: 0xF2F4F8)
        assertColor(KelinColor.accent, hex: 0x8C7CFF)
        assertColor(KelinColor.danger, hex: 0xDB6B78)
    }

    func testSpacingRadiusAndSizeTokensMatchVisualSpecification() {
        XCTAssertEqual(
            [
                KelinSpacing.xSmall,
                KelinSpacing.small,
                KelinSpacing.compact,
                KelinSpacing.standard,
                KelinSpacing.pageHorizontal,
                KelinSpacing.section,
                KelinSpacing.largeSection,
            ],
            [4, 8, 12, 16, 20, 24, 32]
        )
        XCTAssertEqual(
            [KelinRadius.small, KelinRadius.standard, KelinRadius.large],
            [14, 18, 24]
        )
        XCTAssertEqual(KelinSize.minimumTouchTarget, 44)
        XCTAssertEqual(KelinSize.primaryButtonHeight, 52)
        XCTAssertEqual(KelinSize.inputMinimumHeight, 48)
        XCTAssertEqual(KelinSize.roomActionDockHeight, 72)
    }

    func testTypographyMetricsMatchVisualSpecification() {
        XCTAssertEqual(KelinTypography.largeTitle.size, 28)
        XCTAssertEqual(KelinTypography.largeTitle.lineHeight, 34)
        XCTAssertEqual(KelinTypography.pageTitle.size, 20)
        XCTAssertEqual(KelinTypography.body.size, 15)
        XCTAssertEqual(KelinTypography.body.lineHeight, 21)
        XCTAssertEqual(KelinTypography.label.size, 12)
        XCTAssertEqual(KelinTypography.label.lineHeight, 16)
    }

    private func assertColor(
        _ color: Color,
        hex: UInt32,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let resolved = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        XCTAssertTrue(
            resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha),
            file: file,
            line: line
        )
        XCTAssertEqual(red, CGFloat((hex >> 16) & 0xFF) / 255, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(green, CGFloat((hex >> 8) & 0xFF) / 255, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(blue, CGFloat(hex & 0xFF) / 255, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(alpha, 1, accuracy: 0.001, file: file, line: line)
    }
}
