import Foundation
import SwiftData

@Model
final class CachedMessage {
    @Attribute(.unique) var id: UUID
    var accountUserID: UUID
    var clientID: UUID
    var payloadData: Data
    var sendStateRawValue: String
    var createdAt: Date

    var sendState: CachedMessageSendState {
        get { CachedMessageSendState(rawValue: sendStateRawValue) ?? .queued }
        set { sendStateRawValue = newValue.rawValue }
    }

    init(
        id: UUID,
        accountUserID: UUID,
        clientID: UUID,
        payloadData: Data,
        sendState: CachedMessageSendState,
        createdAt: Date
    ) {
        self.id = id
        self.accountUserID = accountUserID
        self.clientID = clientID
        self.payloadData = payloadData
        self.sendStateRawValue = sendState.rawValue
        self.createdAt = createdAt
    }
}
