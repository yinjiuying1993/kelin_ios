import Foundation
import SwiftData

@Model
final class CachedBootstrap {
    @Attribute(.unique) var accountUserID: UUID
    var payloadData: Data
    var snapshotVersion: Int
    var updatedAt: Date

    init(
        accountUserID: UUID,
        payloadData: Data,
        snapshotVersion: Int,
        updatedAt: Date
    ) {
        self.accountUserID = accountUserID
        self.payloadData = payloadData
        self.snapshotVersion = snapshotVersion
        self.updatedAt = updatedAt
    }
}
