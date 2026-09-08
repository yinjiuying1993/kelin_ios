import Foundation
import SwiftData

@Model
final class Draft {
    @Attribute(.unique) var id: UUID
    var accountUserID: UUID
    var kindRawValue: String
    var payloadData: Data
    var updatedAt: Date

    var kind: DraftKind {
        get { DraftKind(rawValue: kindRawValue) ?? .chat }
        set { kindRawValue = newValue.rawValue }
    }

    init(
        id: UUID,
        accountUserID: UUID,
        kind: DraftKind,
        payloadData: Data,
        updatedAt: Date
    ) {
        self.id = id
        self.accountUserID = accountUserID
        self.kindRawValue = kind.rawValue
        self.payloadData = payloadData
        self.updatedAt = updatedAt
    }
}
