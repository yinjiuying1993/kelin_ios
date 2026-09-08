import Foundation

@MainActor
@Observable
final class AppEnvironment {
    let dateProvider: any DateProvider
    let auth: any AuthServiceProtocol

    init(
        dateProvider: any DateProvider = SystemDateProvider(),
        auth: any AuthServiceProtocol = MockAuthService()
    ) {
        self.dateProvider = dateProvider
        self.auth = auth
    }

    static var preview: AppEnvironment {
        AppEnvironment(dateProvider: SystemDateProvider())
    }
}
