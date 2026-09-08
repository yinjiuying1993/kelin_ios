import Foundation
import SwiftData

@Model
final class CachedPostcard {
    @Attribute(.unique) var id: UUID
    var accountUserID: UUID
    var payloadData: Data
    var isRead: Bool
    var createdAt: Date

    init(
        id: UUID,
        accountUserID: UUID,
        payloadData: Data,
        isRead: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.accountUserID = accountUserID
        self.payloadData = payloadData
        self.isRead = isRead
        self.createdAt = createdAt
    }
}
