import Foundation
import SwiftData

@Model
final class CachedMemory {
    @Attribute(.unique) var id: UUID
    var accountUserID: UUID
    var payloadData: Data
    var isTombstone: Bool
    var updatedAt: Date

    init(
        id: UUID,
        accountUserID: UUID,
        payloadData: Data,
        isTombstone: Bool,
        updatedAt: Date
    ) {
        self.id = id
        self.accountUserID = accountUserID
        self.payloadData = payloadData
        self.isTombstone = isTombstone
        self.updatedAt = updatedAt
    }
}
