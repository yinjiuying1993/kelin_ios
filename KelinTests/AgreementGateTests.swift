import SwiftData
import XCTest
@testable import Kelin

@MainActor
final class AgreementGateTests: XCTestCase {
    func testSubmitAgreementWithoutCheckboxDoesNothing() async throws {
        let (appState, gate) = try makeAppState()

        appState.beginLaunch()
        await waitForPhase(.needsAgreement, in: appState)

        await appState.submitAgreement(
            aiDisclosureAccepted: false,
            hasViewedUserTerms: false,
            hasViewedDataNotice: false
        )

        XCTAssertEqual(appState.phase, .needsAgreement)
        XCTAssertNil(appState.pendingConsents)
        let calls = await gate.attemptCountValue()
        XCTAssertEqual(calls, 0)
    }

    func testSubmitAgreementAdvancesToEggSelectionWhenAccepted() async throws {
        let (appState, gate) = try makeAppState()

        appState.beginLaunch()
        await waitForPhase(.needsAgreement, in: appState)

        await appState.submitAgreement(
            aiDisclosureAccepted: true,
            hasViewedUserTerms: true,
            hasViewedDataNotice: true
        )

        XCTAssertEqual(appState.phase, .needsEggSelection)
        XCTAssertNotNil(appState.pendingConsents)
        XCTAssertTrue(appState.pendingConsents?.aiDisclosure.explicitlyAccepted == true)
        let calls = await gate.attemptCountValue()
        XCTAssertEqual(calls, 1)
    }

    func testSubmitAgreementFailureKeepsAgreementPhaseAndAllowsRetry() async throws {
        let gate = MockAgreementGateService(
            configuration: .init(error: .networkUnavailable)
        )
        let (appState, _) = try makeAppState(gate: gate)

        appState.beginLaunch()
        await waitForPhase(.needsAgreement, in: appState)

        await appState.submitAgreement(
            aiDisclosureAccepted: true,
            hasViewedUserTerms: true,
            hasViewedDataNotice: true
        )

        XCTAssertEqual(appState.phase, .needsAgreement)
        XCTAssertEqual(appState.agreementError, .networkUnavailable)
        XCTAssertNil(appState.pendingConsents)

        await gate.setConfiguration(.success)
        appState.clearAgreementError()
        await appState.submitAgreement(
            aiDisclosureAccepted: true,
            hasViewedUserTerms: true,
            hasViewedDataNotice: true
        )

        XCTAssertEqual(appState.phase, .needsEggSelection)
        XCTAssertNil(appState.agreementError)
    }

    func testAgreementViewCanBeConstructed() throws {
        let appState = try makeAppState().appState
        _ = AgreementView(appState: appState)
    }

    private func makeAppState(
        gate: MockAgreementGateService = MockAgreementGateService()
    ) throws -> (appState: AppState, gate: MockAgreementGateService) {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let appState = AppState(
            auth: MockAuthService(),
            localStore: LocalStore(modelContainer: container),
            bootstrapService: MockBootstrapService(mode: .newUser),
            agreementGate: gate
        )
        return (appState, gate)
    }

    private func waitForPhase(
        _ expected: AppPhase,
        in appState: AppState,
        timeout: Duration = .seconds(2)
    ) async {
        let deadline = ContinuousClock.now + timeout

        while ContinuousClock.now < deadline {
            if appState.phase == expected {
                return
            }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }

        XCTFail("Expected phase \(expected), got \(appState.phase)")
    }
}
