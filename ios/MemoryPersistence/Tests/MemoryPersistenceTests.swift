import Foundation
import MemoryCore
import Testing

@testable import MemoryPersistence

@Test func textSurvivesReopenAndRejectsWhitespace() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let first = try MemoryRepository(directory: directory)
    #expect(throws: MemoryError.emptyText) { try first.saveText("  \n") }
    let saved = try first.saveText("Купить шампунь")
    let reopened = try MemoryRepository(directory: directory)
    #expect(try reopened.item(id: saved.id)?.original == .text("Купить шампунь"))
    #expect(try reopened.search("шампунь").map(\.id) == [saved.id])
}

@Test func imageCaptureIsIdempotentAndOriginalIsImmutable() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repo = try MemoryRepository(directory: directory)
    let bytes = Data([0, 1, 2, 3, 4])
    let first = try repo.saveImage(bytes, captureID: "capture-1")
    let repeatCapture = try repo.saveImage(Data([9]), captureID: "capture-1")
    #expect(first.id == repeatCapture.id)
    try repo.confirmText("исправлено", for: first.id)
    #expect(try repo.originalData(for: first.id) == bytes)
    #expect(try repo.search("исправлено").map(\.id) == [first.id])
}

@Test func repeatedShareOfSameBytesUsesStableCaptureID() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repo = try MemoryRepository(directory: directory)
    let data = Data([10, 20, 30])
    let firstID = ShareCaptureID.forImage(data)
    let secondID = ShareCaptureID.forImage(data)
    #expect(firstID == secondID)
    let first = try repo.saveImage(data, captureID: firstID)
    let second = try repo.saveImage(data, captureID: secondID)
    #expect(first.id == second.id)
    #expect(try repo.allItems().count == 1)
}

@Test func groupDeletionKeepsItemAndOtherMembership() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repo = try MemoryRepository(directory: directory)
    let item = try repo.saveText("Заметка")
    let one = try repo.createGroup("Работа")
    let two = try repo.createGroup("Личное")
    try repo.add(item: item.id, to: one.id)
    try repo.add(item: item.id, to: two.id)
    try repo.deleteGroup(one.id)
    #expect(try repo.item(id: item.id) != nil)
    #expect(try repo.groups(for: item.id).map(\.id) == [two.id])
}

@Test func editedAndDeletedItemsLeaveSearch() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repo = try MemoryRepository(directory: directory)
    let item = try repo.saveImage(Data([1, 2]), captureID: "unique")
    let originalPath: String
    if case .image(let path, _) = item.original {
        originalPath = path
    } else {
        Issue.record("Expected image original")
        return
    }
    try repo.confirmText("врач", for: item.id)
    try repo.confirmText("дерматолог", for: item.id)
    #expect(try repo.search("врач").isEmpty)
    #expect(try repo.search("дерматолог").count == 1)
    try repo.deleteItem(item.id)
    #expect(try repo.search("дерматолог").isEmpty)
    #expect(try repo.item(id: item.id) == nil)
    #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent(originalPath).path))
}

@Test func startupRemovesOrphanedImageAfterInterruptedCapture() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    _ = try MemoryRepository(directory: directory)
    let orphan = directory.appendingPathComponent("originals/orphan.image")
    try Data([1]).write(to: orphan)
    _ = try MemoryRepository(directory: directory)
    #expect(!FileManager.default.fileExists(atPath: orphan.path))
}

@Test func failedImageFileWriteLeavesNoRecordOrOriginal() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let originals = directory.appendingPathComponent("originals", isDirectory: true)
    defer {
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: originals.path)
        try? FileManager.default.removeItem(at: directory)
    }
    let repo = try MemoryRepository(directory: directory)
    try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: originals.path)
    do {
        _ = try repo.saveImage(Data([1, 2, 3]), captureID: "failed-write")
        Issue.record("Expected the file write to fail")
    } catch {}
    #expect(try repo.allItems().isEmpty)
    #expect(try FileManager.default.contentsOfDirectory(atPath: originals.path).isEmpty)
}
