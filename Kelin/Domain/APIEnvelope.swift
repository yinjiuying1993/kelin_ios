import Foundation

struct APIErrorPayload: Decodable, Sendable, Equatable {
    let code: String
    let message: String
    let retryable: Bool
    let details: [String: String]?

    init(code: String, message: String, retryable: Bool, details: [String: String]? = nil) {
        self.code = code
        self.message = message
        self.retryable = retryable
        self.details = details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)
        retryable = try container.decodeIfPresent(Bool.self, forKey: .retryable) ?? false
        details = (try? container.decodeIfPresent([String: APIJSONScalar].self, forKey: .details))?
            .mapValues(\.stringValue)
    }

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case retryable
        case details
    }

    var detailKeys: [String] {
        (details ?? [:]).keys.sorted()
    }
}

struct APIEnvelope<T: Decodable & Sendable>: Decodable, Sendable {
    let ok: Bool
    let data: T?
    let error: APIErrorPayload?
    let requestID: String
    let serverTime: Date

    init(
        ok: Bool,
        data: T?,
        error: APIErrorPayload?,
        requestID: String,
        serverTime: Date
    ) {
        self.ok = ok
        self.data = data
        self.error = error
        self.requestID = requestID
        self.serverTime = serverTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decodeIfPresent(T.self, forKey: .data)
        error = try container.decodeIfPresent(APIErrorPayload.self, forKey: .error)
        requestID = try container.decode(String.self, forKey: .requestID)
        serverTime = try container.decode(Date.self, forKey: .serverTime)
        if let ok = try container.decodeIfPresent(Bool.self, forKey: .ok) {
            self.ok = ok
        } else {
            ok = error == nil && data != nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case ok
        case data
        case error
        case requestID = "request_id"
        case serverTime = "server_time"
    }
}

struct APIJSONScalar: Decodable, Sendable, Equatable {
    let stringValue: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            stringValue = "null"
        } else if let value = try? container.decode(String.self) {
            stringValue = value
        } else if let value = try? container.decode(Bool.self) {
            stringValue = value ? "true" : "false"
        } else if let value = try? container.decode(Int.self) {
            stringValue = String(value)
        } else if let value = try? container.decode(Double.self) {
            stringValue = String(value)
        } else if let values = try? container.decode([String].self) {
            stringValue = values.joined(separator: ",")
        } else {
            stringValue = "complex"
        }
    }
}

struct APISendResult<T: Sendable>: Sendable {
    let payload: T
    let serverTime: Date
    let requestID: String
}

enum APIDecoding {
    static func makeJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    static func encodeBody<T: Encodable>(_ value: T) throws -> Data {
        try makeJSONEncoder().encode(value)
    }

    static func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let withFractionalSeconds = ISO8601DateFormatter()
            withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFractionalSeconds.date(from: value) {
                return date
            }

            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]
            guard let date = standard.date(from: value) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid ISO8601 date: \(value)"
                )
            }
            return date
        }
        return decoder
    }
}
