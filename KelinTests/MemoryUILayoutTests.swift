import SwiftUI
import UIKit
import XCTest
@testable import Kelin

@MainActor
final class MemoryUILayoutTests: XCTestCase {
    func testLayoutTokensMatchDesign() {
        XCTAssertEqual(MemoryLayout.headerHeight, 48)
        XCTAssertEqual(MemoryLayout.filterChipHeight, KelinSize.filterChipHeight)
        XCTAssertEqual(MemoryLayout.emptyActionWidth, 180)
        XCTAssertEqual(MemoryLayout.emptyActionHeight, 48)
        XCTAssertGreaterThanOrEqual(KelinSize.minimumTouchTarget, 44)
    }

    func testEmptyAndListDoNotOverflowReferenceWidths() {
        let widths: [CGFloat] = [375, 393, 430]
        for width in widths {
            XCTAssertLessThanOrEqual(overflow(for: makeView(memories: []), width: width), 0.5)
            XCTAssertLessThanOrEqual(overflow(for: makeView(memories: sampleMemories), width: width), 0.5)
        }
    }

    private func makeView(memories: [MemorySummary]) -> MemoryView {
        MemoryView(
            viewModel: MemoryViewModel(memories: memories, spiritName: "雾生", isOffline: false),
            onBack: {},
            onTalk: {}
        )
    }

    private func overflow(for view: MemoryView, width: CGFloat) -> CGFloat {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 852)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        return maxX(in: controller.view) - width
    }

    private func maxX(in view: UIView) -> CGFloat {
        view.subviews.reduce(view.frame.maxX) { max($0, maxX(in: $1)) }
    }

    private var sampleMemories: [MemorySummary] {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        return [
            MemorySummary(
                id: UUID(uuidString: "50000000-0000-4000-8000-000000000001")!,
                type: "preference",
                summary: "不要叫宝宝，要叫阿年",
                status: "active",
                createdAt: now
            ),
            MemorySummary(
                id: UUID(uuidString: "50000000-0000-4000-8000-000000000002")!,
                type: "sight",
                summary: "雨夜里的一盏路灯",
                status: "active",
                createdAt: now.addingTimeInterval(-86_400)
            ),
            MemorySummary(
                id: UUID(uuidString: "50000000-0000-4000-8000-000000000003")!,
                type: "knowledge",
                summary: "STAR 法则",
                status: "active",
                createdAt: now.addingTimeInterval(-172_800)
            ),
        ]
    }
}
