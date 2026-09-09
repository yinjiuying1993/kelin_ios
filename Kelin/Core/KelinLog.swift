import Foundation
import OSLog

enum KelinLog {
    static let subsystem = "com.yinjiuying.kelin"

    static let launch = Logger(subsystem: subsystem, category: "launch")
    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let api = Logger(subsystem: subsystem, category: "api")
    static let onboarding = Logger(subsystem: subsystem, category: "onboarding")

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
