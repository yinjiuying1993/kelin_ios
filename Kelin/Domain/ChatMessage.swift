import Foundation

struct MessageSourceRef: Equatable, Sendable, Codable, Identifiable {
    let kind: String
    let title: String
    let memoryID: UUID?
    let url: String?

    var id: String {
        if let memoryID {
            return "\(kind)-\(memoryID.uuidString)"
        }
        if let url {
            return "\(kind)-\(url)"
        }
        return "\(kind)-\(title)"
    }

    init(kind: String, title: String, memoryID: UUID?, url: String? = nil) {
        self.kind = kind
        self.title = title
        self.memoryID = memoryID
        self.url = url
    }
}

struct ChatMessage: Equatable, Sendable, Codable, Identifiable {
    enum Role: String, Codable, Sendable {
        case user
        case spirit
    }

    enum Source: String, Codable, Sendable {
        case text
        case voice
        case onboarding
    }

    enum Status: String, Codable, Sendable {
        case queued
        case sending
        case accepted
        case generated
        case failed
    }

    let id: UUID
    let clientID: UUID
    let role: Role
    let content: String
    let source: Source
    let status: Status
    let sourceRefs: [MessageSourceRef]
    let createdAt: Date

    init(
        id: UUID,
        clientID: UUID,
        role: Role,
        content: String,
        source: Source,
        status: Status,
        sourceRefs: [MessageSourceRef] = [],
        createdAt: Date
    ) {
        self.id = id
        self.clientID = clientID
        self.role = role
        self.content = content
        self.source = source
        self.status = status
        self.sourceRefs = sourceRefs
        self.createdAt = createdAt
    }

    func with(
        id: UUID? = nil,
        status: Status? = nil,
        content: String? = nil,
        sourceRefs: [MessageSourceRef]? = nil
    ) -> ChatMessage {
        ChatMessage(
            id: id ?? self.id,
            clientID: clientID,
            role: role,
            content: content ?? self.content,
            source: source,
            status: status ?? self.status,
            sourceRefs: sourceRefs ?? self.sourceRefs,
            createdAt: createdAt
        )
    }
}

struct MessagesPage: Equatable, Sendable {
    let items: [ChatMessage]
    let nextCursor: String?
    let hasMore: Bool
    let snapshotAt: Date
}
