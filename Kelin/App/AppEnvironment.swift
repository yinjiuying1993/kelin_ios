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
    let chatService: any ChatServiceProtocol
    let messagesService: any MessagesServiceProtocol
    let extractService: any ExtractServiceProtocol
    let memoryService: any MemoryServiceProtocol
    let feedService: any FeedServiceProtocol
    let speechService: any SpeechServiceProtocol
    let pactService: any PactServiceProtocol
    let socialService: any SocialServiceProtocol
    let deviceService: any DeviceServiceProtocol
    let reportService: any ReportServiceProtocol
    let settingsService: any SettingsServiceProtocol
    let modelContainer: ModelContainer
    let usesRemoteAPI: Bool
    let apiBaseURL: URL?
    let healthLiveProbe: (@Sendable () async throws -> String)?

    init(
        dateProvider: any DateProvider = SystemDateProvider(),
        auth: any AuthServiceProtocol = MockAuthService(),
        bootstrapService: any BootstrapServiceProtocol = MockBootstrapService(),
        agreementGate: any AgreementGateServiceProtocol = MockAgreementGateService(),
        hatchService: any HatchServiceProtocol = MockHatchService(),
        onboardingChatService: any OnboardingChatServiceProtocol = MockOnboardingChatService(),
        onboardingCompleteService: any OnboardingCompleteServiceProtocol = MockOnboardingCompleteService(),
        chatService: any ChatServiceProtocol = MockChatService(),
        messagesService: any MessagesServiceProtocol = MockMessagesService(),
        extractService: any ExtractServiceProtocol = MockExtractService(),
        memoryService: any MemoryServiceProtocol = MockMemoryService(),
        feedService: any FeedServiceProtocol = MockFeedService(),
        speechService: any SpeechServiceProtocol = MockSpeechService(),
        pactService: any PactServiceProtocol = MockPactService(),
        socialService: any SocialServiceProtocol = MockSocialService(),
        deviceService: any DeviceServiceProtocol = MockDeviceService(),
        reportService: any ReportServiceProtocol = MockReportService(),
        settingsService: any SettingsServiceProtocol = MockSettingsService(),
        modelContainer: ModelContainer,
        usesRemoteAPI: Bool = false,
        apiBaseURL: URL? = nil,
        healthLiveProbe: (@Sendable () async throws -> String)? = nil
    ) {
        self.dateProvider = dateProvider
        self.auth = auth
        self.bootstrapService = bootstrapService
        self.agreementGate = agreementGate
        self.hatchService = hatchService
        self.onboardingChatService = onboardingChatService
        self.onboardingCompleteService = onboardingCompleteService
        self.chatService = chatService
        self.messagesService = messagesService
        self.extractService = extractService
        self.memoryService = memoryService
        self.feedService = feedService
        self.speechService = speechService
        self.pactService = pactService
        self.socialService = socialService
        self.deviceService = deviceService
        self.reportService = reportService
        self.settingsService = settingsService
        self.modelContainer = modelContainer
        self.usesRemoteAPI = usesRemoteAPI
        self.apiBaseURL = apiBaseURL
        self.healthLiveProbe = healthLiveProbe
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
            chatService: chatService,
            messagesService: messagesService,
            extractService: extractService,
            memoryService: memoryService,
            feedService: feedService,
            speechService: speechService,
            pactService: pactService,
            socialService: socialService,
            deviceService: deviceService,
            reportService: reportService,
            settingsService: settingsService,
            sessionStore: sessionStore,
            bootstrapCoordinator: bootstrapCoordinator,
            syncCoordinator: syncCoordinator,
            usesRemoteAPI: usesRemoteAPI,
            apiBaseURL: apiBaseURL,
            healthLiveProbe: healthLiveProbe
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
            agreementGate: LocalAgreementGateService(),
            hatchService: APIHatchService(client: client),
            onboardingChatService: APIOnboardingChatService(client: client),
            onboardingCompleteService: APIOnboardingCompleteService(client: client),
            chatService: APIChatService(client: client),
            messagesService: APIMessagesService(client: client),
            extractService: APIExtractService(client: client),
            memoryService: APIMemoryService(client: client),
            feedService: APIFeedService(client: client),
            speechService: APISpeechService(client: client, apiBaseURL: config.apiBaseURL),
            pactService: APIPactService(client: client),
            socialService: APISocialService(client: client),
            deviceService: APIDeviceService(client: client),
            reportService: APIReportService(client: client),
            settingsService: APISettingsService(client: client),
            modelContainer: try KelinModelContainerFactory.makeDefaultContainer(),
            usesRemoteAPI: true,
            apiBaseURL: config.apiBaseURL,
            healthLiveProbe: { try await client.checkHealthLive() }
        )
    }
}
