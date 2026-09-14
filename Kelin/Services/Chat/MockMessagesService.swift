import Foundation

actor MockMessagesService: MessagesServiceProtocol {
    struct Configuration: Sendable {
        var pages: [MessagesPage]
        var error: AppError?

        static func defaultPages(pageSize: Int = 30, totalCount: Int = 75) -> Configuration {
            Configuration(pages: MessagesDraftFixtures.paginatedPages(pageSize: pageSize, totalCount: totalCount))
        }
    }

    private var configuration: Configuration
    private(set) var requests: [(cursor: String?, limit: Int)] = []

    init(configuration: Configuration = Configuration(pages: [])) {
        self.configuration = configuration
    }

    func setConfiguration(_ configuration: Configuration) {
        self.configuration = configuration
    }

    func recordedRequests() -> [(cursor: String?, limit: Int)] {
        requests
    }

    func fetchMessages(cursor: String?, limit: Int) async throws -> MessagesPage {
        requests.append((cursor, limit))

        if let error = configuration.error {
            throw error
        }

        guard !configuration.pages.isEmpty else {
            return MessagesPage(items: [], nextCursor: nil, hasMore: false, snapshotAt: MessagesDraftFixtures.snapshotAt)
        }

        if let cursor {
            guard cursor.hasPrefix("cursor-page-"),
                  let pageNumber = Int(cursor.dropFirst("cursor-page-".count)),
                  pageNumber > 0,
                  pageNumber < configuration.pages.count else {
                throw AppError.invalidInput
            }
            return configuration.pages[pageNumber]
        }

        return configuration.pages[0]
    }
}
