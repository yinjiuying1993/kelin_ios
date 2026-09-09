import Foundation
import SwiftData

@MainActor
final class AppEnvironment {
    let dateProvider: any DateProvider
    let auth: any AuthServiceProtocol
    let bootstrapService: any BootstrapServiceProtocol
    let agreementGate: any AgreementGateServiceProtocol
    let hatchService: any HatchServiceProtocol
    let onboardingChatService: any OnboardingChatServiceProtocol
    let onboardingCompleteService: any OnboardingCompleteServiceProtocol
    let modelContainer: ModelContainer

    init(
        dateProvider: any DateProvider = SystemDateProvider(),
        auth: any AuthServiceProtocol = MockAuthService(),
        bootstrapService: any BootstrapServiceProtocol = MockBootstrapService(),
        agreementGate: any AgreementGateServiceProtocol = MockAgreementGateService(),
        hatchService: any HatchServiceProtocol = MockHatchService(),
        onboardingChatService: any OnboardingChatServiceProtocol = MockOnboardingChatService(),
        onboardingCompleteService: any OnboardingCompleteServiceProtocol = MockOnboardingCompleteService(),
        modelContainer: ModelContainer
    ) {
        self.dateProvider = dateProvider
        self.auth = auth
        self.bootstrapService = bootstrapService
        self.agreementGate = agreementGate
        self.hatchService = hatchService
        self.onboardingChatService = onboardingChatService
        self.onboardingCompleteService = onboardingCompleteService
        self.modelContainer = modelContainer
    }

    func makeLocalStore() -> LocalStore {
        LocalStore(modelContainer: modelContainer)
    }

    func makeAppState(
        sessionStore: SessionStore = SessionStore(),
        bootstrapCoordinator: BootstrapCoordinator = BootstrapCoordinator(),
        syncCoordinator: SyncCoordinator? = nil
    ) -> AppState {
        AppState(
            auth: auth,
            localStore: makeLocalStore(),
            bootstrapService: bootstrapService,
            agreementGate: agreementGate,
            hatchService: hatchService,
            onboardingChatService: onboardingChatService,
            onboardingCompleteService: onboardingCompleteService,
            sessionStore: sessionStore,
            bootstrapCoordinator: bootstrapCoordinator,
            syncCoordinator: syncCoordinator
        )
    }

    static var preview: AppEnvironment {
        AppEnvironment(modelContainer: try! KelinModelContainerFactory.makeInMemoryContainer())
    }

    static func makeDefault() throws -> AppEnvironment {
        let config = try AppConfig.load()
        let auth = SupabaseAuthService(config: config)
        let client = APIClient(config: config, auth: auth)
        return AppEnvironment(
            auth: auth,
            bootstrapService: APIBootstrapService(client: client),
            agreementGate: MockAgreementGateService(),
            hatchService: APIHatchService(client: client),
            onboardingChatService: APIOnboardingChatService(client: client),
            onboardingCompleteService: APIOnboardingCompleteService(client: client),
            modelContainer: try KelinModelContainerFactory.makeDefaultContainer()
        )
    }
}
