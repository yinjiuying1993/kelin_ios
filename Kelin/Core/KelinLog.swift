import Foundation
import OSLog

enum KelinLog {
    static let subsystem = "com.yinjiuying.kelin"

    static let launch = Channel(category: "launch")
    static let auth = Channel(category: "auth")
    static let api = Channel(category: "api")
    static let onboarding = Channel(category: "onboarding")

    enum Level: Int, Equatable, Sendable {
        case debug
        case info
        case error
    }

    struct Channel: Sendable {
        let category: String
        private let logger: Logger

        init(category: String) {
            self.category = category
            self.logger = Logger(subsystem: KelinLog.subsystem, category: category)
        }

        func debug(_ message: String) {
            emit(.debug, message)
        }

        func info(_ message: String) {
            emit(.info, message)
        }

        func error(_ message: String) {
            emit(.error, message)
        }

        func log(_ level: Level, _ message: String) {
            emit(level, message)
        }

        private func emit(_ level: Level, _ message: String) {
            switch level {
            case .debug:
                logger.debug("\(message, privacy: .public)")
            case .info:
                logger.info("\(message, privacy: .public)")
            case .error:
                logger.error("\(message, privacy: .public)")
            }

            #if DEBUG
            if KelinLog.shouldPrintToConsole(level, verbose: KelinLog.isVerboseEnabled) {
                print("[Kelin/\(category)] \(message)")
            }
            #endif
        }
    }

    static var isVerboseEnabled: Bool {
        ProcessInfo.processInfo.environment["KELIN_VERBOSE_LOG"] == "1"
    }

    static func shouldPrintToConsole(_ level: Level, verbose: Bool) -> Bool {
        level != .debug || verbose
    }

    static func apiSuccessLevel(method: String, path _: String) -> Level {
        method == "GET" ? .debug : .info
    }

    static func shortID(_ uuid: UUID) -> String {
        String(uuid.uuidString.prefix(8)).lowercased()
    }

    static func snapshotSummary(_ snapshot: BootstrapSnapshot) -> String {
        let spirit: String
        if let value = snapshot.spirit {
            spirit = "spirit=\(shortID(value.id)) egg=\(value.egg.rawValue) version=\(value.version)"
        } else {
            spirit = "spirit=nil"
        }

        return [
            "schema=\(snapshot.schemaVersion)",
            "snapshot=\(snapshot.snapshotVersion)",
            spirit,
            "required=\(snapshot.onboarding.required)",
            "step=\(snapshot.onboarding.step)/\(snapshot.onboarding.totalSteps)",
            "completed=\(snapshot.onboarding.completedAt != nil)",
        ].joined(separator: " ")
    }
}
