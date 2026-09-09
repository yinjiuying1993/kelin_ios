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

    init(
        path: String,
        method: HTTPMethod,
        body: Data? = nil,
        timeout: TimeInterval = APIEndpoint.defaultGETTimeout,
        allowsConnectionRetry: Bool = false
    ) {
        self.path = path
        self.method = method
        self.body = body
        self.timeout = timeout
        self.allowsConnectionRetry = allowsConnectionRetry
    }

    static let defaultPOSTTimeout: TimeInterval = 30

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
            allowsConnectionRetry: allowsConnectionRetry
        )
    }
}
