import Foundation

protocol MessagesServiceProtocol: Sendable {
    func fetchMessages(cursor: String?, limit: Int) async throws -> MessagesPage
}
