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
            guard let date = parseDate(value) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid ISO8601 date"
                )
            }
            return date
        }
        return decoder
    }

    static func parseDate(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]

        let candidates = [raw, normalizeDateString(raw)]
        for candidate in Set(candidates) {
            if let date = fractional.date(from: candidate) {
                return date
            }
            if let date = standard.date(from: candidate) {
                return date
            }
        }

        if raw.count == 10, raw.filter({ $0 == "-" }).count == 2 {
            return parseDate(raw + "T00:00:00Z")
        }

        if !hasTimeZone(raw) {
            return parseDate(raw + "Z")
        }

        return nil
    }

    static func decodingDebugDescription(_ error: Error) -> String {
        guard let decodingError = error as? DecodingError else {
            return String(describing: type(of: error))
        }

        switch decodingError {
        case .keyNotFound(let key, let context):
            return "key_not_found \(key.stringValue) path=\(codingPath(context))"
        case .typeMismatch(_, let context):
            return "type_mismatch path=\(codingPath(context))"
        case .valueNotFound(_, let context):
            return "value_not_found path=\(codingPath(context))"
        case .dataCorrupted(let context):
            return "data_corrupted path=\(codingPath(context))"
        @unknown default:
            return "decoding"
        }
    }

    private static func codingPath(_ context: DecodingError.Context) -> String {
        context.codingPath.map(\.stringValue).joined(separator: ".")
    }

    private static func hasTimeZone(_ value: String) -> Bool {
        guard let timeSeparator = value.firstIndex(of: "T") else {
            return value.hasSuffix("Z")
        }
        let timePart = value[value.index(after: timeSeparator)...]
        return timePart.contains("Z") || timePart.contains("+") || timePart.contains("-")
    }

    private static func normalizeDateString(_ value: String) -> String {
        var normalized = value.replacingOccurrences(of: "+00:00", with: "Z")
        normalized = normalized.replacingOccurrences(of: "-00:00", with: "Z")
        return normalizeFractionalSeconds(normalized)
    }

    private static func normalizeFractionalSeconds(_ value: String) -> String {
        guard let dot = value.lastIndex(of: ".") else {
            return value
        }

        let digitsStart = value.index(after: dot)
        var digitsEnd = digitsStart
        while digitsEnd < value.endIndex, value[digitsEnd].isNumber {
            digitsEnd = value.index(after: digitsEnd)
        }

        let digits = value[digitsStart..<digitsEnd]
        guard digits.count != 3 else {
            return value
        }

        let millis: String
        if digits.count > 3 {
            millis = String(digits.prefix(3))
        } else {
            millis = digits + String(repeating: "0", count: 3 - digits.count)
        }
        return String(value[..<digitsStart]) + millis + String(value[digitsEnd...])
    }
}
