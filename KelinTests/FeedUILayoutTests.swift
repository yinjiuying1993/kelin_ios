import SwiftUI
import UIKit
import XCTest
@testable import Kelin

@MainActor
final class FeedUILayoutTests: XCTestCase {
    func testLayoutTokensMatchDesign() {
        XCTAssertEqual(FeedLayout.headerHeight, 48)
        XCTAssertEqual(FeedLayout.actionHeight, 44)
        XCTAssertEqual(FeedLayout.chipHeight, KelinSize.filterChipHeight)
        XCTAssertEqual(FeedLayout.cardRadius, KelinRadius.standard)
        XCTAssertGreaterThanOrEqual(KelinSize.minimumTouchTarget, 44)
    }

    func testFeedViewDoesNotOverflowReferenceWidths() {
        for width in [CGFloat(375), 393, 430] {
            XCTAssertLessThanOrEqual(overflow(width: width), 0.5, "width=\(width)")
        }
    }

    private func overflow(width: CGFloat) -> CGFloat {
        let view = FeedView(
            viewModel: FeedViewModel(quotas: [], isOffline: false),
            onBack: {}
        )
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 852)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        return maxX(in: controller.view) - width
    }

    private func maxX(in view: UIView) -> CGFloat {
        view.subviews.reduce(view.frame.maxX) { max($0, maxX(in: $1)) }
    }
}
