import Foundation

enum FeedEmotion: String, CaseIterable, Equatable, Sendable {
    case calm
    case happy
    case tired
    case anxious
    case angry

    var title: String {
        switch self {
        case .calm:
            String(localized: "平静")
        case .happy:
            String(localized: "开心")
        case .tired:
            String(localized: "疲惫")
        case .anxious:
            String(localized: "焦虑")
        case .angry:
            String(localized: "生气")
        }
    }
}

enum FeedLocationCategory: String, CaseIterable, Equatable, Sendable {
    case landmark
    case park
    case cafe
    case school
    case workplace
    case other

    var title: String {
        switch self {
        case .landmark:
            String(localized: "地标")
        case .park:
            String(localized: "公园")
        case .cafe:
            String(localized: "咖啡馆")
        case .school:
            String(localized: "学校")
        case .workplace:
            String(localized: "工作地")
        case .other:
            String(localized: "其他")
        }
    }
}

enum FeedCardState: Equatable, Sendable {
    case idle
    case submitting
    case success
    case failed
}

enum FeedPresentationRules {
    static let knowledgeClosedRange = 1...10_000
    static let promiseCreateClosedRange = 1...500
    static let promisePatchClosedRange = 1...200
    static let locationLabelClosedRange = 1...80
    static let locationCityClosedRange = 1...40
    static let defaultFoodLimit = 3

    static func foodQuotaText(from quotas: [QuotaEntry]) -> String {
        if let food = quotas.first(where: { $0.capability == .food }) {
            return String(localized: "今日 \(food.used)/\(food.limit)")
        }
        return String(localized: "今日 \(0)/\(defaultFoodLimit)")
    }

    static func quotaText(for kind: QuotaKind, from quotas: [QuotaEntry], defaultLimit: Int) -> String {
        if let entry = quotas.first(where: { $0.capability == kind }) {
            return String(localized: "今日 \(entry.used)/\(entry.limit)")
        }
        return String(localized: "今日 \(0)/\(defaultLimit)")
    }

    static func validateKnowledge(_ raw: String) throws -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard knowledgeClosedRange.contains(text.count) else {
            throw AppError.invalidInput
        }
        return text
    }

    static func validatePromiseText(_ raw: String, range: ClosedRange<Int>) throws -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard range.contains(text.count) else {
            throw AppError.invalidInput
        }
        return text
    }

    static func validateLocation(
        city: String,
        label: String,
        category: FeedLocationCategory?
    ) throws -> (city: String, label: String, category: String?) {
        let cityText = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let labelText = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard locationCityClosedRange.contains(cityText.count) else {
            throw AppError.invalidInput
        }
        guard locationLabelClosedRange.contains(labelText.count) else {
            throw AppError.invalidInput
        }
        return (cityText, labelText, category?.rawValue)
    }

    static func isReachableSightUploadHost(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased(), !host.isEmpty else {
            return false
        }
        if host == "localhost" || host == "127.0.0.1" || host == "0.0.0.0" || host == "::1" {
            return false
        }
        return !host.hasSuffix(".invalid")
    }

    static func isFourSegmentSightPath(_ path: String) -> Bool {
        let parts = path.split(separator: "/").map(String.init)
        guard parts.count == 4 else {
            return false
        }
        return parts[0] == "sight-temp"
            && !parts[1].isEmpty
            && !parts[2].isEmpty
            && parts[3].hasSuffix(".jpg")
    }
}
