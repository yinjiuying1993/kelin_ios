import Foundation

enum MemoryCodec {
    static func encode(_ memory: MemorySummary) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(memory)
    }

    static func decode(_ data: Data) throws -> MemorySummary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MemorySummary.self, from: data)
    }
}
