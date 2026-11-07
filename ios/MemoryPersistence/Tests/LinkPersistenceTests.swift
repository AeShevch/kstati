import Foundation
import GRDB
import MemoryCore
import Testing

@testable import MemoryPersistence

@Test func preLinkDatabaseMigratesWithoutDataLoss() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let textID: UUID
    let imageID: UUID
    do {
        let legacy = try MemoryRepository(directory: directory)
        textID = try legacy.saveText("Старая заметка").id
        imageID = try legacy.saveImage(Data([4, 5]), captureID: "legacy-image").id
    }
    let database = try DatabaseQueue(path: directory.appendingPathComponent("memory.sqlite").path)
    try database.write { db in
        try db.execute(sql: "DELETE FROM grdb_migrations WHERE identifier='add-original-url'")
        try db.execute(sql: "ALTER TABLE memory_items DROP COLUMN original_url")
    }
    let migrated = try MemoryRepository(directory: directory)
    #expect(try migrated.item(id: textID)?.original == .text("Старая заметка"))
    #expect(try migrated.item(id: imageID)?.kind == .image)
    #expect(try migrated.saveLink("https://example.com", captureID: "after-migration").kind == .link)
}

@Test func linkAndExistingRecordsSurviveReopen() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let first = try MemoryRepository(directory: directory)
    let text = try first.saveText("Заметка")
    let image = try first.saveImage(Data([1, 2, 3]), captureID: "old-image")
    let link = try first.saveLink("https://example.com/article", captureID: "share-link:one")
    let reopened = try MemoryRepository(directory: directory)
    #expect(try reopened.item(id: text.id)?.original == .text("Заметка"))
    #expect(try reopened.item(id: image.id)?.original == image.original)
    #expect(try reopened.item(id: link.id)?.original == .link(url: "https://example.com/article"))
    #expect(link.confirmedText == nil)
}

@Test func linkSaveRejectsUnsupportedAddressAndIsIdempotent() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repo = try MemoryRepository(directory: directory)
    #expect(throws: MemoryError.invalidURL) {
        try repo.saveLink("file:///private/test", captureID: "invalid")
    }
    #expect(throws: MemoryError.invalidURL) {
        try repo.saveLink("https:///missing-host", captureID: "invalid-host")
    }
    #expect(try repo.allItems().isEmpty)
    let captureID = ShareCaptureID.forLink("https://example.com/article")
    let first = try repo.saveLink("https://example.com/article", captureID: captureID)
    let second = try repo.saveLink("https://example.com/article", captureID: captureID)
    #expect(first.id == second.id)
    #expect(try repo.allItems().count == 1)
}

@Test func linkSearchFindsURLAndDomainWithoutDuplicates() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repo = try MemoryRepository(directory: directory)
    let link = try repo.saveLink("https://example.com/article?topic=swift_test", captureID: "link-search")
    #expect(try repo.search("example.com").map(\.id) == [link.id])
    #expect(try repo.search("article").map(\.id) == [link.id])
    #expect(try repo.search("swift_test").map(\.id) == [link.id])
    #expect(try repo.search("% ").isEmpty)
    try repo.confirmText("example.com", for: link.id)
    #expect(try repo.search("example.com").map(\.id) == [link.id])
    try repo.deleteItem(link.id)
    #expect(try repo.search("example.com").isEmpty)
}

@Test func failedLinkDatabaseWriteLeavesNoRecord() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repo = try MemoryRepository(directory: directory)
    try repo.setLinkWriteFailureForTests(true)
    #expect(throws: (any Error).self) {
        try repo.saveLink("https://example.com/blocked", captureID: "blocked")
    }
    #expect(try repo.allItems().isEmpty)
    try repo.setLinkWriteFailureForTests(false)
    #expect(try repo.saveLink("https://example.com/blocked", captureID: "blocked").kind == .link)
}
