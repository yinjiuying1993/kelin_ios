import Foundation

actor APIMessagesService: MessagesServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) {
        self.client = client
    }

    func fetchMessages(cursor: String?, limit: Int) async throws -> MessagesPage {
        let dto = try await client.send(
            .messages(cursor: cursor, limit: limit),
            responseType: MessagesPageDTO.self
        )
        return try MessagesMapper.map(dto)
    }
}
