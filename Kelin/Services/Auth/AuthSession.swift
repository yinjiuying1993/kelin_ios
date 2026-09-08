import Foundation

struct AuthSession: Equatable, Sendable {
    let userID: UUID
    let accessToken: String
    let expiresAt: Date
}
