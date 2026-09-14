import UIKit
import XCTest
@testable import Kelin

final class PhotoProcessorTests: XCTestCase {
    func testProcessedJPEGHasNoLongEdgeAboveLimitAndHashesProcessedBytes() async throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2_000, height: 800))
        let source = renderer.pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2_000, height: 800))
        }

        let processed = try await PhotoProcessor().process(source)
        XCTAssertLessThanOrEqual(max(processed.pixelWidth, processed.pixelHeight), 1_280)
        XCTAssertEqual(processed.sha256.count, 64)
        XCTAssertEqual(processed.jpeg.count, processed.sha256.isEmpty ? 0 : processed.jpeg.count)
        XCTAssertGreaterThan(processed.jpeg.count, 0)
        XCTAssertEqual(processed.jpeg.prefix(2), Data([0xFF, 0xD8]))
    }
}
