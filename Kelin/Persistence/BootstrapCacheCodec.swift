import Foundation

enum BootstrapCacheCodec {
    static func encode(_ snapshot: BootstrapSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    static func decode(_ data: Data) throws -> BootstrapSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BootstrapSnapshot.self, from: data)
    }
}
