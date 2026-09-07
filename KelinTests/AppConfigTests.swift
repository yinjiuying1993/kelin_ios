import XCTest
@testable import Kelin

final class AppConfigTests: XCTestCase {
    func testValidValuesProduceConfiguration() throws {
        let config = try AppConfig(infoDictionary: validValues())

        XCTAssertEqual(config.supabaseURL.absoluteString, "https://example.supabase.co")
        XCTAssertEqual(config.supabaseAnonKey, "synthetic-anon-key")
        XCTAssertEqual(config.apiBaseURL.absoluteString, "https://api.example.com")
        XCTAssertEqual(config.environment, .development)
    }

    func testMissingRequiredValueFailsWithKeyOnly() {
        var values = validValues()
        values.removeValue(forKey: AppConfig.Key.apiBaseURL)

        XCTAssertThrowsError(try AppConfig(infoDictionary: values)) { error in
            XCTAssertEqual(
                error as? AppConfigError,
                .missingValue(key: AppConfig.Key.apiBaseURL)
            )
        }
    }

    func testUnresolvedPlaceholderIsRejected() {
        var values = validValues()
        values[AppConfig.Key.supabaseAnonKey] = "REPLACE_WITH_SUPABASE_ANON_KEY"

        XCTAssertThrowsError(try AppConfig(infoDictionary: values)) { error in
            XCTAssertEqual(
                error as? AppConfigError,
                .unresolvedPlaceholder(key: AppConfig.Key.supabaseAnonKey)
            )
        }
    }

    func testInvalidURLIsRejectedWithoutReturningRawValue() {
        var values = validValues()
        values[AppConfig.Key.apiBaseURL] = "not-a-url"

        XCTAssertThrowsError(try AppConfig(infoDictionary: values)) { error in
            XCTAssertEqual(
                error as? AppConfigError,
                .invalidURL(key: AppConfig.Key.apiBaseURL)
            )
        }
    }

    func testUnknownEnvironmentIsRejected() {
        var values = validValues()
        values[AppConfig.Key.appEnvironment] = "staging"

        XCTAssertThrowsError(try AppConfig(infoDictionary: values)) { error in
            XCTAssertEqual(error as? AppConfigError, .invalidEnvironment)
        }
    }

    private func validValues() -> [String: Any] {
        [
            AppConfig.Key.supabaseURL: "https://example.supabase.co",
            AppConfig.Key.supabaseAnonKey: "synthetic-anon-key",
            AppConfig.Key.apiBaseURL: "https://api.example.com",
            AppConfig.Key.appEnvironment: "dev",
        ]
    }
}
