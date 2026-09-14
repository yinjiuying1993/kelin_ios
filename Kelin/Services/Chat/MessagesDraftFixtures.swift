import Foundation

enum MessagesDraftFixtures {
    // Source: kelin_server_technical_spec.md §10.2 (draft, Mock-only; OpenAPI SHA pending)

    static let snapshotAt = Date(timeIntervalSince1970: 1_700_100_000)

    static func sampleMessage(
        index: Int,
        role: ChatMessage.Role = .user,
        status: ChatMessage.Status = .generated,
        createdAt: Date? = nil
    ) -> ChatMessage {
        let messageID = UUID(uuidString: String(format: "10000000-0000-4000-8000-%012X", index))!
        let clientID = role == .user
            ? UUID(uuidString: String(format: "20000000-0000-4000-8000-%012X", index))!
            : messageID
        let timestamp = createdAt ?? snapshotAt.addingTimeInterval(TimeInterval(index))

        return ChatMessage(
            id: messageID,
            clientID: clientID,
            role: role,
            content: "fixture-message-\(index)",
            source: .text,
            status: status,
            sourceRefs: [],
            createdAt: timestamp
        )
    }

    static func paginatedPages(pageSize: Int = 30, totalCount: Int = 75) -> [MessagesPage] {
        let allMessages = (0..<totalCount).map { index in
            sampleMessage(
                index: index + 1,
                role: index.isMultiple(of: 2) ? .spirit : .user,
                status: index.isMultiple(of: 2) ? .generated : .accepted,
                createdAt: snapshotAt.addingTimeInterval(TimeInterval(totalCount - index))
            )
        }

        var pages: [MessagesPage] = []
        var start = 0
        var pageIndex = 0

        while start < allMessages.count {
            let end = min(start + pageSize, allMessages.count)
            let slice = Array(allMessages[start..<end])
            let hasMore = end < allMessages.count
            pages.append(
                MessagesPage(
                    items: slice,
                    nextCursor: hasMore ? "cursor-page-\(pageIndex + 1)" : nil,
                    hasMore: hasMore,
                    snapshotAt: snapshotAt
                )
            )
            start = end
            pageIndex += 1
        }

        return pages
    }

    static let firstPageEnvelope = """
    {
      "ok": true,
      "data": {
        "items": [
          {
            "id": "10000000-0000-4000-8000-000000000002",
            "client_id": "20000000-0000-4000-8000-000000000002",
            "role": "spirit",
            "content": "知道了，阿年。",
            "source": "text",
            "status": "generated",
            "source_refs": [],
            "created_at": "2026-09-10T08:00:02Z"
          },
          {
            "id": "10000000-0000-4000-8000-000000000001",
            "client_id": "20000000-0000-4000-8000-000000000001",
            "role": "user",
            "content": "不要叫我宝宝，叫阿年",
            "source": "text",
            "status": "accepted",
            "source_refs": [],
            "created_at": "2026-09-10T08:00:01Z"
          }
        ],
        "next_cursor": "cursor-page-1",
        "has_more": true,
        "snapshot_at": "2026-09-10T08:00:02Z"
      },
      "error": null,
      "request_id": "fixture-messages-page-1",
      "server_time": "2026-09-10T08:00:02Z"
    }
    """
}
