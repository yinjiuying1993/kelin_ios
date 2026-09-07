import Foundation

@MainActor
@Observable
final class AppEnvironment {
    let dateProvider: any DateProvider

    init(dateProvider: any DateProvider = SystemDateProvider()) {
        self.dateProvider = dateProvider
    }

    static var preview: AppEnvironment {
        AppEnvironment(dateProvider: SystemDateProvider())
    }
}
