import SwiftUI
import UIKit
import XCTest
@testable import Kelin

@MainActor
final class RoomLayoutTests: XCTestCase {
    private let referenceWidths: [CGFloat] = [375, 393, 430]
    private let referenceHeights: [CGFloat] = [667, 852]

    func testRoomViewDoesNotHorizontallyOverflowReferenceWidths() {
        for state in [SpiritStatus.home, .study, .away, .lost] {
            for width in referenceWidths {
                for height in referenceHeights {
                    let overflow = horizontalOverflow(
                        for: makeRoomView(status: state, isOffline: false),
                        width: width,
                        height: height
                    )
                    XCTAssertLessThanOrEqual(
                        overflow,
                        0.5,
                        "state=\(state.rawValue) width=\(width) height=\(height)"
                    )
                }
            }
        }
    }

    func testOfflineRoomKeepsLayoutWithinReferenceWidths() {
        for width in referenceWidths {
            let overflow = horizontalOverflow(
                for: makeRoomView(status: .home, isOffline: true),
                width: width,
                height: 852
            )
            XCTAssertLessThanOrEqual(overflow, 0.5, "offline width=\(width)")
        }
    }

    func testRoomDockRespectsStandardContentWidth() {
        XCTAssertLessThanOrEqual(KelinLayout.standardContentWidth, 353)
        for width in referenceWidths {
            let allowed = min(width - KelinSpacing.pageHorizontal * 2, KelinLayout.standardContentWidth)
            XCTAssertGreaterThanOrEqual(allowed, 280, "dock should remain usable at width=\(width)")
        }
    }

    func testLongStatusTextUsesMultilineLayoutWithoutOverflow() {
        for width in referenceWidths {
            let overflow = horizontalOverflow(
                for: RoomView(
                    viewModel: RoomViewModel(
                        spirit: sampleSpirit(status: .lost),
                        room: nil,
                        isOffline: true
                    ),
                    router: AppRouter()
                ),
                width: width,
                height: 852
            )
            XCTAssertLessThanOrEqual(overflow, 0.5, "long copy width=\(width)")
        }
    }

    private func makeRoomView(status: SpiritStatus, isOffline: Bool) -> RoomView {
        RoomView(
            viewModel: RoomViewModel(
                spirit: sampleSpirit(status: status),
                room: sampleRoom(status: status),
                isOffline: isOffline
            ),
            router: AppRouter()
        )
    }

    private func horizontalOverflow(for view: RoomView, width: CGFloat, height: CGFloat) -> CGFloat {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        return maxSubviewMaxX(in: controller.view) - width
    }

    private func maxSubviewMaxX(in view: UIView) -> CGFloat {
        var maxX = view.frame.maxX
        for subview in view.subviews {
            maxX = max(maxX, maxSubviewMaxX(in: subview))
        }
        return maxX
    }

    private func sampleSpirit(status: SpiritStatus) -> Spirit {
        Spirit(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            userID: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
            name: "雾生",
            egg: .warm,
            inviteCode: "ABCD2345",
            traits: TraitValues(closeness: 65, curiosity: 55, sharpness: 35, nocturnal: 40, stubborn: 40),
            vitals: VitalValues(hunger: 80, energy: 80, mood: 60, bond: 0),
            stage: .whelp,
            status: status,
            scholarMarks: ["reader"],
            preferences: SpiritPreferences(
                ttsOn: false,
                pushOn: false,
                visitOn: true,
                dndStart: "23:00",
                dndEnd: "08:00",
                timezone: "Asia/Shanghai",
                defaultCity: nil,
                locationWeatherOn: false,
                remoteSearchOn: true
            ),
            awayUntil: nil,
            studyUntil: nil,
            lastInteractAt: Date(timeIntervalSince1970: 1_700_000_000),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            version: 1
        )
    }

    private func sampleRoom(status: SpiritStatus) -> RoomSnapshot {
        RoomSnapshot(
            weather: "cloudy",
            layers: [
                RoomLayer(key: "bookshelf", variant: "default"),
                RoomLayer(key: "door", variant: "default"),
                RoomLayer(key: "window", variant: "default"),
            ],
            letter: status == .lost ? "room.letter.lost" : nil,
            pendingSightID: nil,
            unreadFootprintCount: status == .home ? 2 : 0,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
