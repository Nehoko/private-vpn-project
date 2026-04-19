import Foundation

struct SubscriberStore {
    private let fileManager = FileManager.default

    func load() throws -> PersistenceSnapshot {
        let url = try storageURL()
        guard fileManager.fileExists(atPath: url.path) else {
            return PersistenceSnapshot(updatedAt: .now, subscribers: [])
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PersistenceSnapshot.self, from: data)
    }

    func save(subscribers: [Subscriber], updatedAt: Date = .now) throws -> PersistenceSnapshot {
        let snapshot = PersistenceSnapshot(updatedAt: updatedAt, subscribers: subscribers)
        let url = try storageURL()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: url, options: .atomic)
        return snapshot
    }

    private func storageURL() throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = appSupport.appendingPathComponent("PrivateVPNAdmin", isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent("subscribers.json")
    }
}
