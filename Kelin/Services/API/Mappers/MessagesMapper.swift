import Foundation

enum MessagesMapper {
    static func map(_ dto: MessagesPageDTO) throws -> MessagesPage {
        MessagesPage(
            items: try dto.items.map(mapMessage),
            nextCursor: dto.nextCursor,
            hasMore: dto.hasMore,
            snapshotAt: dto.snapshotAt
        )
    }

    static func mapMessage(_ dto: MessageItemDTO) throws -> ChatMessage {
        ChatMessage(
            id: dto.id,
            clientID: dto.clientID ?? dto.id,
            role: try mapRole(dto.role),
            content: dto.content,
            source: try mapSource(dto.source),
            status: try mapStatus(dto.status),
            sourceRefs: dto.sourceRefs.map(mapSourceRef),
            createdAt: dto.createdAt
        )
    }

    private static func mapRole(_ rawValue: String) throws -> ChatMessage.Role {
        guard let role = ChatMessage.Role(rawValue: rawValue) else {
            throw AppError.decoding
        }
        return role
    }

    private static func mapSource(_ rawValue: String) throws -> ChatMessage.Source {
        guard let source = ChatMessage.Source(rawValue: rawValue) else {
            throw AppError.decoding
        }
        return source
    }

    private static func mapStatus(_ rawValue: String) throws -> ChatMessage.Status {
        guard let status = ChatMessage.Status(rawValue: rawValue) else {
            throw AppError.decoding
        }
        return status
    }

    static func mapSourceRef(_ dto: MessageSourceRefDTO) -> MessageSourceRef {
        MessageSourceRef(
            kind: dto.type,
            title: displayTitle(for: dto),
            memoryID: dto.type == "web" ? nil : dto.id,
            url: dto.url
        )
    }

    private static func displayTitle(for dto: MessageSourceRefDTO) -> String {
        if let title = dto.title, !title.isEmpty {
            return title
        }
        if dto.type == "web", let url = dto.url, let host = URL(string: url)?.host, !host.isEmpty {
            return host
        }
        switch dto.type {
        case "memory":
            return "记忆"
        case "pact":
            return "契约"
        case "builtin_bank", "knowledge":
            return "题库"
        case "web":
            return "来源"
        default:
            return dto.type
        }
    }
}
