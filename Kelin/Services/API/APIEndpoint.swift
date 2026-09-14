import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIEndpoint: Sendable {
    static let defaultGETTimeout: TimeInterval = 15

    let path: String
    let method: HTTPMethod
    let body: Data?
    let timeout: TimeInterval
    let allowsConnectionRetry: Bool
    let contentType: String?

    init(
        path: String,
        method: HTTPMethod,
        body: Data? = nil,
        timeout: TimeInterval = APIEndpoint.defaultGETTimeout,
        allowsConnectionRetry: Bool = false,
        contentType: String? = nil
    ) {
        self.path = path
        self.method = method
        self.body = body
        self.timeout = timeout
        self.allowsConnectionRetry = allowsConnectionRetry
        self.contentType = contentType
    }

    static let defaultPOSTTimeout: TimeInterval = 30
    static let chatPOSTTimeout: TimeInterval = 25
    static let extractPOSTTimeout: TimeInterval = 30
    static let transcribePOSTTimeout: TimeInterval = 28
    static let synthesizePOSTTimeout: TimeInterval = 23

    static func get(
        _ path: String,
        timeout: TimeInterval = defaultGETTimeout
    ) -> APIEndpoint {
        APIEndpoint(
            path: path,
            method: .get,
            timeout: timeout,
            allowsConnectionRetry: true
        )
    }

    static func messages(cursor: String?, limit: Int = 30) -> APIEndpoint {
        var items = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor, !cursor.isEmpty {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }

        var components = URLComponents()
        components.path = "/messages"
        components.queryItems = items
        return get(components.string ?? "/messages?limit=\(limit)")
    }

    static func post(
        _ path: String,
        body: Data,
        timeout: TimeInterval = defaultPOSTTimeout,
        allowsConnectionRetry: Bool = false
    ) -> APIEndpoint {
        APIEndpoint(
            path: path,
            method: .post,
            body: body,
            timeout: timeout,
            allowsConnectionRetry: allowsConnectionRetry,
            contentType: "application/json"
        )
    }

    static func postMultipart(
        _ path: String,
        body: Data,
        boundary: String,
        timeout: TimeInterval = transcribePOSTTimeout
    ) -> APIEndpoint {
        APIEndpoint(
            path: path,
            method: .post,
            body: body,
            timeout: timeout,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }

    static func patch(
        _ path: String,
        body: Data,
        timeout: TimeInterval = defaultPOSTTimeout
    ) -> APIEndpoint {
        APIEndpoint(path: path, method: .patch, body: body, timeout: timeout)
    }

    static func delete(
        _ path: String,
        body: Data,
        timeout: TimeInterval = defaultPOSTTimeout
    ) -> APIEndpoint {
        APIEndpoint(path: path, method: .delete, body: body, timeout: timeout)
    }

    static func memories(
        filter: MemoryFilter,
        cursor: String?,
        limit: Int = 30
    ) -> APIEndpoint {
        var items = [
            URLQueryItem(name: "filter", value: filter.rawValue),
            URLQueryItem(name: "limit", value: String(min(max(limit, 1), 50))),
        ]
        if let cursor, !cursor.isEmpty {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }

        var components = URLComponents()
        components.path = "/memories"
        components.queryItems = items
        return get(components.string ?? "/memories?filter=\(filter.rawValue)&limit=\(limit)")
    }

    static func friends(cursor: String?, limit: Int = 30) -> APIEndpoint {
        pagedGet("/friends", cursor: cursor, extra: [], limit: limit)
    }

    static func postcards(unreadOnly: Bool, cursor: String?, limit: Int = 30) -> APIEndpoint {
        pagedGet(
            "/postcards",
            cursor: cursor,
            extra: unreadOnly ? [URLQueryItem(name: "unread_only", value: "true")] : [],
            limit: limit
        )
    }

    private static func pagedGet(
        _ path: String,
        cursor: String?,
        extra: [URLQueryItem],
        limit: Int
    ) -> APIEndpoint {
        var items = extra
        items.append(URLQueryItem(name: "limit", value: String(min(max(limit, 1), 50))))
        if let cursor, !cursor.isEmpty {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        var components = URLComponents()
        components.path = path
        components.queryItems = items
        return get(components.string ?? "\(path)?limit=\(limit)")
    }
}
