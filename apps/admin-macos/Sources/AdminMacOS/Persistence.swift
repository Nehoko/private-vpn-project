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

    func copyVPNConfig(from sourceURL: URL, for subscriberID: UUID) throws -> (fileName: String, relativePath: String) {
        let sanitizedFileName = sanitizedAttachmentName(sourceURL.lastPathComponent)
        let folder = try attachmentsFolderURL().appendingPathComponent(subscriberID.uuidString, isDirectory: true)

        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        let targetURL = folder.appendingPathComponent(sanitizedFileName, isDirectory: false)
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        try fileManager.copyItem(at: sourceURL, to: targetURL)
        return (sanitizedFileName, subscriberID.uuidString + "/" + sanitizedFileName)
    }

    func attachmentURL(relativePath: String?) throws -> URL? {
        guard let relativePath else {
            return nil
        }

        let url = try attachmentsFolderURL(create: false).appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        return url
    }

    func removeVPNConfig(relativePath: String?) throws {
        guard let url = try attachmentURL(relativePath: relativePath) else {
            return
        }

        try fileManager.removeItem(at: url)
    }

    private func storageURL() throws -> URL {
        let folder = try baseFolderURL()
        return folder.appendingPathComponent("subscribers.json")
    }

    private func attachmentsFolderURL(create: Bool = true) throws -> URL {
        let folder = try baseFolderURL().appendingPathComponent("vpn-configs", isDirectory: true)
        if create, !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    private func baseFolderURL() throws -> URL {
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
        return folder
    }

    private func sanitizedAttachmentName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.replacingOccurrences(of: "/", with: "-")
        return cleaned.isEmpty ? "vpn-config.conf" : cleaned
    }
}
