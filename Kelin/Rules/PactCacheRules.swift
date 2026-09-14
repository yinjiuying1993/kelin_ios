import Foundation

enum PactCacheRules {
    static func resolvePhase(pact: PactSummary?, sessionStatus: String?) -> PactScreenPhase {
        guard let pact else {
            return .unsigned
        }

        let status = pact.status.lowercased()
        if status == "completed" {
            return .completed
        }
        if status == "abandoned" {
            return .unsigned
        }
        if status != "active" {
            return .unsigned
        }

        switch sessionStatus?.lowercased() {
        case "answered", "skipped":
            return .todayCompleted
        default:
            return .active
        }
    }

    static func serverDay(from serverTime: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: serverTime)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func shanghaiTimeZone() -> TimeZone {
        TimeZone(identifier: "Asia/Shanghai") ?? TimeZone(secondsFromGMT: 8 * 3600)!
    }

    static func encodeCreateBody(theme: String, title: String, clientID: UUID, notesMemoryID: UUID?) throws -> Data {
        try APIDecoding.encodeBody(
            CreatePactRequestDTO(
                clientID: clientID,
                theme: theme,
                title: title,
                notesMemoryID: notesMemoryID
            )
        )
    }

    static func forbiddenRequestKeys() -> Set<String> {
        ["score", "mark", "finalized", "completeness", "scholar_mark", "bond"]
    }
}
