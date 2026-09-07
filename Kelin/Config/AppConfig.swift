import Foundation

enum AppRuntimeEnvironment: String, CaseIterable, Equatable, Sendable {
    case development = "dev"
    case production = "prod"
}

enum AppConfigError: Error, Equatable, Sendable {
    case missingValue(key: String)
    case unresolvedPlaceholder(key: String)
    case invalidURL(key: String)
    case invalidEnvironment
}

struct AppConfig: Equatable, Sendable {
    enum Key {
        static let supabaseURL = "SUPABASE_URL"
        static let supabaseAnonKey = "SUPABASE_ANON_KEY"
        static let apiBaseURL = "API_BASE_URL"
        static let appEnvironment = "APP_ENV"
    }

    let supabaseURL: URL
    let supabaseAnonKey: String
    let apiBaseURL: URL
    let environment: AppRuntimeEnvironment

    init(infoDictionary: [String: Any]) throws {
        let supabaseURLValue = try Self.requiredValue(
            for: Key.supabaseURL,
            in: infoDictionary
        )
        let supabaseAnonKey = try Self.requiredValue(
            for: Key.supabaseAnonKey,
            in: infoDictionary
        )
        let apiBaseURLValue = try Self.requiredValue(
            for: Key.apiBaseURL,
            in: infoDictionary
        )
        let environmentValue = try Self.requiredValue(
            for: Key.appEnvironment,
            in: infoDictionary
        )

        self.supabaseURL = try Self.url(
            from: supabaseURLValue,
            key: Key.supabaseURL
        )
        self.supabaseAnonKey = supabaseAnonKey
        self.apiBaseURL = try Self.url(
            from: apiBaseURLValue,
            key: Key.apiBaseURL
        )

        guard let environment = AppRuntimeEnvironment(rawValue: environmentValue) else {
            throw AppConfigError.invalidEnvironment
        }
        self.environment = environment
    }

    static func load(from bundle: Bundle = .main) throws -> AppConfig {
        try AppConfig(infoDictionary: bundle.infoDictionary ?? [:])
    }

    private static func requiredValue(
        for key: String,
        in infoDictionary: [String: Any]
    ) throws -> String {
        guard
            let rawValue = infoDictionary[key] as? String,
            !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw AppConfigError.missingValue(key: key)
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.contains("$("), !value.contains("REPLACE_WITH_") else {
            throw AppConfigError.unresolvedPlaceholder(key: key)
        }
        return value
    }

    private static func url(from value: String, key: String) throws -> URL {
        guard
            let components = URLComponents(string: value),
            let scheme = components.scheme?.lowercased(),
            scheme == "https" || scheme == "http",
            components.host != nil,
            let url = components.url
        else {
            throw AppConfigError.invalidURL(key: key)
        }
        return url
    }
}
