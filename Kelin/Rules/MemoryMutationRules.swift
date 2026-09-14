import Foundation

enum MemoryMutationRules {
    static let summaryClosedRange = 1...500
    static let clearConfirm = "CLEAR_ALL_MEMORIES"

    static func validateSummary(_ raw: String) throws -> String {
        let summary = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard summaryClosedRange.contains(summary.count) else {
            throw AppError.invalidInput
        }
        return summary
    }

    static func canClearAll(isOffline: Bool) -> Bool {
        !isOffline
    }
}
