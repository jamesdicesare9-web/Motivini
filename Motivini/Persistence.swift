import Foundation

actor Persistence {
    static let shared = Persistence()
    private init() {}

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private func fileURL(_ name: String) throws -> URL {
        let dir = try FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        return dir.appendingPathComponent(name)
    }

    func save<T: Encodable>(_ value: T, to name: String) async throws {
        let url = try fileURL(name)
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic) // atomic write
    }

    func load<T: Decodable>(_ type: T.Type, from name: String) async -> T? {
        do {
            let url = try fileURL(name)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            return try decoder.decode(type, from: data)
        } catch { return nil }
    }
}
