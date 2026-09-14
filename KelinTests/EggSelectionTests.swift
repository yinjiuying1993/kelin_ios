import SwiftData
import XCTest
@testable import Kelin

@MainActor
final class EggSelectionTests: XCTestCase {
    func testVariableSelectionMapsToWildEgg() async throws {
        let hatch = MockHatchService(mode: .success(.wild))
        let (appState, _) = try await makeAppStateAtEggSelection(hatch: hatch)

        await appState.createSpirit(selectedOption: .variable)

        let requests = await hatch.recordedRequests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.egg, .wild)
        XCTAssertEqual(appState.phase, .needsFirstConversation(step: 1))
        XCTAssertEqual(appState.sessionStore.snapshot?.spirit?.egg, .wild)
    }

    func testWarmAndColdSelectionsMapCorrectly() async throws {
        for option in [EggSelectionOption.warm, .cold] {
            let hatch = MockHatchService(mode: .success(option.eggType))
            let (appState, _) = try await makeAppStateAtEggSelection(hatch: hatch)

            await appState.createSpirit(selectedOption: option)

            let requests = await hatch.recordedRequests()
            XCTAssertEqual(requests.first?.egg, option.eggType)
        }
    }

    func testRetryReusesStableClientID() async throws {
        let hatch = MockHatchService(mode: .businessError(.networkUnavailable))
        let (appState, _) = try await makeAppStateAtEggSelection(hatch: hatch)

        await appState.createSpirit(selectedOption: .warm)
        XCTAssertEqual(appState.hatchError, .networkUnavailable)
        XCTAssertEqual(appState.phase, .needsEggSelection)

        let failedRequests = await hatch.recordedRequests()
        let clientID = try XCTUnwrap(failedRequests.first?.clientID)

        await hatch.setMode(.success(.warm))
        appState.clearHatchError()
        await appState.createSpirit(selectedOption: .warm)

        let allRequests = await hatch.recordedRequests()
        XCTAssertEqual(allRequests.count, 2)
        XCTAssertEqual(allRequests[0].clientID, clientID)
        XCTAssertEqual(allRequests[1].clientID, clientID)
        XCTAssertEqual(appState.phase, .needsFirstConversation(step: 1))
    }

    func testConcurrentSubmitIsIgnored() async throws {
        let hatch = MockHatchService(mode: .success(.warm), delay: .milliseconds(100))
        let (appState, _) = try await makeAppStateAtEggSelection(hatch: hatch)

        async let first: Void = appState.createSpirit(selectedOption: .warm)
        async let second: Void = appState.createSpirit(selectedOption: .cold)
        _ = await (first, second)

        let requests = await hatch.recordedRequests()
        XCTAssertEqual(requests.count, 1)
    }

    func testCreateSpiritRequiresPendingConsents() async throws {
        let hatch = MockHatchService()
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let appState = AppState(
            auth: MockAuthService(),
            localStore: LocalStore(modelContainer: container),
            bootstrapService: MockBootstrapService(mode: .newUser),
            hatchService: hatch
        )

        await appState.createSpirit(selectedOption: .warm)

        let requests = await hatch.recordedRequests()
        XCTAssertTrue(requests.isEmpty)
    }

    func testRelaunchReusesPersistedSpiritClientID() async throws {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let localStore = LocalStore(modelContainer: container)
        let auth = MockAuthService()
        let hatch = MockHatchService(mode: .businessError(.networkUnavailable))

        let firstLaunch = AppState(
            auth: auth,
            localStore: localStore,
            bootstrapService: MockBootstrapService(mode: .newUser),
            hatchService: hatch
        )
        firstLaunch.beginLaunch()
        await waitForPhase(.needsAgreement, in: firstLaunch)
        await firstLaunch.submitAgreement(
            aiDisclosureAccepted: true,
            hasViewedUserTerms: true,
            hasViewedDataNotice: true
        )
        await firstLaunch.createSpirit(selectedOption: .warm)

        let persistedRequests = await hatch.recordedRequests()
        let persistedID = try XCTUnwrap(persistedRequests.first?.clientID)

        let retryHatch = MockHatchService(mode: .success(.warm))
        let relaunch = AppState(
            auth: auth,
            localStore: localStore,
            bootstrapService: MockBootstrapService(mode: .newUser),
            hatchService: retryHatch
        )
        relaunch.beginLaunch()
        await waitForPhase(.needsAgreement, in: relaunch)
        await relaunch.submitAgreement(
            aiDisclosureAccepted: true,
            hasViewedUserTerms: true,
            hasViewedDataNotice: true
        )
        await relaunch.createSpirit(selectedOption: .warm)

        let retryRequests = await retryHatch.recordedRequests()
        XCTAssertEqual(retryRequests.count, 1)
        XCTAssertEqual(retryRequests.first?.clientID, persistedID)
        XCTAssertEqual(relaunch.phase, .needsFirstConversation(step: 1))
    }

    func testCreateSpiritConflictRefreshesBootstrap() async throws {
        let hatch = MockHatchService(mode: .businessError(.conflict))
        let bootstrap = MockBootstrapService(mode: .newUser)
        let (appState, _) = try await makeAppStateAtEggSelection(hatch: hatch, bootstrap: bootstrap)

        await bootstrap.setMode(.onboardingUser)
        await appState.createSpirit(selectedOption: .warm)

        XCTAssertNil(appState.hatchError)
        XCTAssertEqual(appState.phase, .needsFirstConversation(step: 4))
        XCTAssertNotNil(appState.sessionStore.snapshot?.spirit)
        XCTAssertEqual(appState.sessionStore.snapshot?.room?.weather, "cloudy")
    }

    func testReturnToAgreementRestoresPreviousPhase() async throws {
        let (appState, _) = try await makeAppStateAtEggSelection()

        appState.returnToAgreement()

        XCTAssertEqual(appState.phase, .needsAgreement)
    }

    func testEggSelectionViewCanBeConstructed() async throws {
        let (appState, _) = try await makeAppStateAtEggSelection()
        _ = EggSelectionView(appState: appState)
    }

    private func makeAppStateAtEggSelection(
        hatch: MockHatchService = MockHatchService(),
        bootstrap: MockBootstrapService = MockBootstrapService(mode: .newUser)
    ) async throws -> (appState: AppState, hatch: MockHatchService) {
        let container = try KelinModelContainerFactory.makeInMemoryContainer()
        let appState = AppState(
            auth: MockAuthService(),
            localStore: LocalStore(modelContainer: container),
            bootstrapService: bootstrap,
            hatchService: hatch
        )

        appState.beginLaunch()
        await waitForPhase(.needsAgreement, in: appState)
        await appState.submitAgreement(
            aiDisclosureAccepted: true,
            hasViewedUserTerms: true,
            hasViewedDataNotice: true
        )
        XCTAssertEqual(appState.phase, .needsEggSelection)

        return (appState, hatch)
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
