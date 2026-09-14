import XCTest
@testable import Kelin

@MainActor
final class PactCacheTests: XCTestCase {
    func testPhaseUsesServerStatusNotLocalArithmetic() {
        XCTAssertEqual(PactCacheRules.resolvePhase(pact: nil, sessionStatus: nil), .unsigned)
        let active = PactSummary(
            id: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            theme: "interview",
            title: "面试题",
            status: "active",
            completeness: 40
        )
        XCTAssertEqual(PactCacheRules.resolvePhase(pact: active, sessionStatus: "ready"), .active)
        XCTAssertEqual(PactCacheRules.resolvePhase(pact: active, sessionStatus: "answered"), .todayCompleted)
        XCTAssertEqual(PactCacheRules.resolvePhase(pact: active, sessionStatus: "skipped"), .todayCompleted)
        let completed = PactSummary(
            id: active.id,
            theme: "interview",
            title: "面试题",
            status: "completed",
            completeness: 91
        )
        XCTAssertEqual(PactCacheRules.resolvePhase(pact: completed, sessionStatus: "answered"), .completed)
    }

    func testPatchReplacesPactAndDoesNotInventCompleteness() throws {
        let store = SessionStore()
        let base = try makeSnapshot(version: 10, pact: nil)
        store.replace(with: base)

        let pact = PactSummary(
            id: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            theme: "interview",
            title: "面试题",
            status: "active",
            completedSessions: 0,
            skippedSessions: 1,
            completeness: 50
        )
        try store.apply(
            SessionPatch(
                snapshotVersion: 11,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                pact: pact,
                serverTime: base.serverTime
            )
        )
        XCTAssertEqual(store.snapshot?.activePact?.completeness, 50)
        XCTAssertEqual(store.snapshot?.activePact?.skippedSessions, 1)
        XCTAssertEqual(store.snapshot?.activePact?.completedSessions, 0)
    }

    func testServerDayUsesShanghaiNotDeviceCalendarAssumption() {
        let date = Date(timeIntervalSince1970: 1_778_630_400)
        XCTAssertEqual(
            PactCacheRules.serverDay(from: date, timeZone: PactCacheRules.shanghaiTimeZone()),
            "2026-05-13"
        )
    }

    private func makeSnapshot(version: Int, pact: PactSummary?) throws -> BootstrapSnapshot {
        BootstrapSnapshot(
            schemaVersion: 2,
            snapshotVersion: version,
            apiVersion: "v1",
            spirit: nil,
            room: nil,
            onboarding: OnboardingState(required: false, step: 5, totalSteps: 5, completedAt: Date()),
            latestMemories: [],
            unreadPostcards: [],
            activePact: pact,
            report: ReportSnapshot(
                status: .locked,
                reportID: nil,
                eligibility: ReportEligibility(
                    isEligible: false,
                    eligibleAt: Date(timeIntervalSince1970: 1),
                    daysRemaining: 3,
                    requiredDialogueRounds: 20,
                    completedDialogueRounds: 0,
                    dialogueRoundsRemaining: 20
                )
            ),
            quotas: [],
            featureFlags: FeatureFlags(remoteSearch: true, imageFeed: true),
            serverTime: Date(timeIntervalSince1970: 1_778_630_400)
        )
    }
}
