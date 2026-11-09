import Foundation
import Testing
import ZIPFoundation

@testable import MemoryPersistence

struct MemoryArchiveExportTests {
    @Test func exportsAllOriginalsAndGroupMemberships() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let repository = try MemoryRepository(directory: root)
        defer { try? FileManager.default.removeItem(at: root) }

        let text = try repository.saveText("Исходный текст")
        try repository.confirmText("Исправленный текст", for: text.id)
        let imageBytes = Data([0, 1, 2, 255])
        let image = try repository.saveImage(imageBytes, captureID: "image")
        _ = try repository.saveLink("https://example.com/article", captureID: "link")
        let first = try repository.createGroup("Первая")
        let second = try repository.createGroup("Вторая")
        try repository.add(item: image.id, to: first.id)
        try repository.add(item: image.id, to: second.id)

        let snapshot = try repository.exportSnapshot()
        #expect(snapshot.records.count == 3)
        #expect(Set(snapshot.memberships.map(\.groupID)) == Set([first.id.uuidString, second.id.uuidString]))
        #expect(snapshot.memberships.allSatisfy { $0.itemID == image.id.uuidString })

        let workspace = root.appendingPathComponent("export")
        let url = try MemoryArchiveExport.prepare(from: repository, in: workspace)
        let archive = try Archive(url: url, accessMode: .read)
        let manifest = try manifest(in: archive)
        #expect(manifest["version"] as? Int == 1)
        #expect((manifest["groups"] as? [[String: Any]])?.count == 2)
        #expect((manifest["memberships"] as? [[String: Any]])?.count == 2)
        let records = try #require(manifest["records"] as? [[String: Any]])
        let textRecord = try #require(records.first { $0["kind"] as? String == "text" })
        #expect(textRecord["confirmedText"] as? String == "Исправленный текст")
        #expect((textRecord["original"] as? [String: String])?["text"] == "Исходный текст")
        let linkRecord = try #require(records.first { $0["kind"] as? String == "link" })
        #expect((linkRecord["original"] as? [String: String])?["url"] == "https://example.com/article")
        let path = try #require(snapshot.records.first { $0.id == image.id }?.original.path)
        #expect(try contents(of: path, in: archive) == imageBytes)

        try FileManager.default.removeItem(at: root.appendingPathComponent(path))
        let failedWorkspace = root.appendingPathComponent("failed")
        #expect(throws: (any Error).self) {
            try MemoryArchiveExport.prepare(from: repository, in: failedWorkspace)
        }
        #expect(!FileManager.default.fileExists(atPath: failedWorkspace.path))
    }

    @Test func exportCanRetryAfterWriteFailure() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let repository = try MemoryRepository(directory: root)
        defer { try? FileManager.default.removeItem(at: root) }
        let unavailable = root.appendingPathComponent("missing/export")
        #expect(throws: (any Error).self) {
            try MemoryArchiveExport.prepare(from: repository, in: unavailable)
        }
        let archive = try Archive(
            url: MemoryArchiveExport.prepare(from: repository, in: root.appendingPathComponent("retry")),
            accessMode: .read)
        #expect((try manifest(in: archive)["records"] as? [[String: Any]])?.isEmpty == true)
        #expect(try repository.allItems().isEmpty)
    }

    private func manifest(in archive: Archive) throws -> [String: Any] {
        let data = try contents(of: "manifest.json", in: archive)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func contents(of path: String, in archive: Archive) throws -> Data {
        let entry = try #require(archive[path])
        var data = Data()
        _ = try archive.extract(entry) { data.append($0) }
        return data
    }
}
