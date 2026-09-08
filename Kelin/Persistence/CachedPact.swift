import Foundation
import SwiftData

@Model
final class CachedPact {
    @Attribute(.unique) var id: UUID
    var accountUserID: UUID
    var payloadData: Data
    var updatedAt: Date

    init(
        id: UUID,
        accountUserID: UUID,
        payloadData: Data,
        updatedAt: Date
    ) {
        self.id = id
        self.accountUserID = accountUserID
        self.payloadData = payloadData
        self.updatedAt = updatedAt
    }
}
