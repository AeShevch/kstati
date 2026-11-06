import CryptoKit
import Foundation
import GRDB
import MemoryCore

public enum ShareCaptureID {
    public static func forImage(_ data: Data) -> String {
        "share-image:" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

public final class MemoryRepository: @unchecked Sendable {
    public let directory: URL
    private let originals: URL
    private let dbPool: DatabasePool

    public init(directory: URL) throws {
        self.directory = directory
        originals = directory.appendingPathComponent("originals", isDirectory: true)
        try FileManager.default.createDirectory(at: originals, withIntermediateDirectories: true)
        var configuration = Configuration()
        configuration.busyMode = .timeout(5)
        dbPool = try DatabasePool(path: directory.appendingPathComponent("memory.sqlite").path,
                                  configuration: configuration)
        var migrator = DatabaseMigrator()
        migrator.registerMigration("initial") { db in
            try db.execute(sql: """
                CREATE TABLE memory_items (
                    id TEXT PRIMARY KEY,
                    capture_id TEXT NOT NULL UNIQUE,
                    kind TEXT NOT NULL,
                    original_text TEXT,
                    original_path TEXT,
                    original_sha256 TEXT,
                    confirmed_text TEXT,
                    confirmed_at REAL,
                    created_at REAL NOT NULL,
                    updated_at REAL NOT NULL
                );
                CREATE TABLE ocr_suggestions (
                    item_id TEXT PRIMARY KEY REFERENCES memory_items(id) ON DELETE CASCADE,
                    value TEXT,
                    status TEXT NOT NULL
                );
                CREATE TABLE memory_groups (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL
                );
                CREATE TABLE memory_item_groups (
                    item_id TEXT NOT NULL REFERENCES memory_items(id) ON DELETE CASCADE,
                    group_id TEXT NOT NULL REFERENCES memory_groups(id) ON DELETE CASCADE,
                    PRIMARY KEY (item_id, group_id)
                );
                CREATE VIRTUAL TABLE memory_fts USING fts5(item_id UNINDEXED, confirmed_text, tokenize='unicode61');
                CREATE TABLE file_cleanup (path TEXT PRIMARY KEY);
                """)
        }
        try migrator.migrate(dbPool)
        try cleanupFiles()
    }

    @discardableResult
    public func saveText(_ text: String, captureID: String = UUID().uuidString) throws -> MemoryItem {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw MemoryError.emptyText }
        return try dbPool.write { db in
            if let existing = try findCapture(captureID, db: db) { return existing }
            let id = UUID()
            let now = Date().timeIntervalSince1970
            try db.execute(sql: """
                INSERT INTO memory_items (id,capture_id,kind,original_text,confirmed_text,confirmed_at,created_at,updated_at)
                VALUES (?,?,?,?,?,?,?,?)
                """, arguments: [id.uuidString, captureID, "text", text, text, now, now, now])
            try index(db: db, id: id, text: text)
            return try load(id, db: db)!
        }
    }

    @discardableResult
    public func saveImage(_ data: Data, captureID: String) throws -> MemoryItem {
        guard !data.isEmpty else { throw MemoryError.emptyImage }
        return try dbPool.write { db in
            if let existing = try findCapture(captureID, db: db) { return existing }
            let id = UUID()
            let filename = id.uuidString + ".image"
            let path = "originals/" + filename
            let temporary = originals.appendingPathComponent(filename + ".tmp")
            let destination = originals.appendingPathComponent(filename)
            let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            do {
                try data.write(to: temporary, options: .atomic)
                try FileManager.default.moveItem(at: temporary, to: destination)
                let now = Date().timeIntervalSince1970
                try db.execute(sql: """
                    INSERT INTO memory_items (id,capture_id,kind,original_path,original_sha256,created_at,updated_at)
                    VALUES (?,?,?,?,?,?,?)
                    """, arguments: [id.uuidString, captureID, "image", path, hash, now, now])
                return try load(id, db: db)!
            } catch {
                try? FileManager.default.removeItem(at: temporary)
                try? FileManager.default.removeItem(at: destination)
                throw error
            }
        }
    }

    public func item(id: UUID) throws -> MemoryItem? {
        try dbPool.read { try load(id, db: $0) }
    }

    public func allItems() throws -> [MemoryItem] {
        try dbPool.read { db in
            try Row.fetchAll(db, sql: "SELECT id FROM memory_items ORDER BY created_at DESC")
                .compactMap { row in try load(UUID(uuidString: row["id"])!, db: db) }
        }
    }

    public func originalData(for id: UUID) throws -> Data? {
        guard let item = try item(id: id) else { return nil }
        guard case .image(let path, _) = item.original else { return nil }
        return try Data(contentsOf: directory.appendingPathComponent(path))
    }

    public func confirmText(_ text: String?, for id: UUID) throws {
        try dbPool.write { db in
            guard try load(id, db: db) != nil else { throw MemoryError.missingItem }
            let value = text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let confirmed = value?.isEmpty == false ? value : nil
            let now = Date().timeIntervalSince1970
            try db.execute(sql: "UPDATE memory_items SET confirmed_text=?, confirmed_at=?, updated_at=? WHERE id=?",
                           arguments: [confirmed, confirmed == nil ? nil : now, now, id.uuidString])
            try index(db: db, id: id, text: confirmed)
        }
    }

    public func setSuggestion(_ suggestion: OcrSuggestion, for id: UUID) throws {
        try dbPool.write { db in
            guard try load(id, db: db) != nil else { throw MemoryError.missingItem }
            try db.execute(sql: """
                INSERT INTO ocr_suggestions (item_id,value,status) VALUES (?,?,?)
                ON CONFLICT(item_id) DO UPDATE SET value=excluded.value,status=excluded.status
                """, arguments: [id.uuidString, suggestion.value, suggestion.status.rawValue])
        }
    }

    public func search(_ query: String) throws -> [MemoryItem] {
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }
        let pattern = words.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }.joined(separator: " ")
        return try dbPool.read { db in
            try Row.fetchAll(db, sql: """
                SELECT m.id FROM memory_fts f JOIN memory_items m ON m.id=f.item_id
                WHERE memory_fts MATCH ? ORDER BY m.created_at DESC
                """, arguments: [pattern])
                .compactMap { row in try load(UUID(uuidString: row["id"])!, db: db) }
        }
    }

    public func createGroup(_ name: String) throws -> MemoryGroup {
        let group = MemoryGroup(id: UUID(), name: name)
        try dbPool.write { db in
            try db.execute(sql: "INSERT INTO memory_groups (id,name) VALUES (?,?)",
                           arguments: [group.id.uuidString, group.name])
        }
        return group
    }

    public func allGroups() throws -> [MemoryGroup] {
        try dbPool.read { db in
            try Row.fetchAll(db, sql: "SELECT id,name FROM memory_groups ORDER BY name")
                .map { MemoryGroup(id: UUID(uuidString: $0["id"])!, name: $0["name"]) }
        }
    }

    public func add(item itemID: UUID, to groupID: UUID) throws {
        try dbPool.write { db in
            try db.execute(sql: "INSERT OR IGNORE INTO memory_item_groups (item_id,group_id) VALUES (?,?)",
                           arguments: [itemID.uuidString, groupID.uuidString])
        }
    }

    public func groups(for itemID: UUID) throws -> [MemoryGroup] {
        try dbPool.read { db in
            try Row.fetchAll(db, sql: """
                SELECT g.id,g.name FROM memory_groups g JOIN memory_item_groups mig ON mig.group_id=g.id
                WHERE mig.item_id=? ORDER BY g.name
                """, arguments: [itemID.uuidString])
                .map { MemoryGroup(id: UUID(uuidString: $0["id"])!, name: $0["name"]) }
        }
    }

    public func remove(item itemID: UUID, from groupID: UUID) throws {
        try dbPool.write { db in
            try db.execute(sql: "DELETE FROM memory_item_groups WHERE item_id=? AND group_id=?",
                           arguments: [itemID.uuidString, groupID.uuidString])
        }
    }

    public func deleteGroup(_ id: UUID) throws {
        try dbPool.write { db in
            try db.execute(sql: "DELETE FROM memory_groups WHERE id=?", arguments: [id.uuidString])
        }
    }

    public func deleteItem(_ id: UUID) throws {
        try dbPool.write { db in
            guard let item = try load(id, db: db) else { return }
            if case .image(let path, _) = item.original {
                try db.execute(sql: "INSERT OR IGNORE INTO file_cleanup (path) VALUES (?)", arguments: [path])
            }
            try db.execute(sql: "DELETE FROM memory_fts WHERE item_id=?", arguments: [id.uuidString])
            try db.execute(sql: "DELETE FROM memory_items WHERE id=?", arguments: [id.uuidString])
        }
        try cleanupFiles()
    }

    public func cleanupFiles() throws {
        try dbPool.write { db in
            let pending = try String.fetchAll(db, sql: "SELECT path FROM file_cleanup")
            for path in pending {
                let url = directory.appendingPathComponent(path)
                do {
                    if FileManager.default.fileExists(atPath: url.path) {
                        try FileManager.default.removeItem(at: url)
                    }
                    try db.execute(sql: "DELETE FROM file_cleanup WHERE path=?", arguments: [path])
                } catch { /* Retain the queued path for the next launch. */ }
            }
            let referenced = Set(try String.fetchAll(db, sql: "SELECT original_path FROM memory_items WHERE original_path IS NOT NULL"))
            for url in try FileManager.default.contentsOfDirectory(at: originals, includingPropertiesForKeys: nil) {
                let path = "originals/" + url.lastPathComponent
                if !referenced.contains(path) {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
    }

    private func findCapture(_ captureID: String, db: Database) throws -> MemoryItem? {
        guard let id: String = try String.fetchOne(db, sql: "SELECT id FROM memory_items WHERE capture_id=?", arguments: [captureID]),
              let uuid = UUID(uuidString: id) else { return nil }
        return try load(uuid, db: db)
    }

    private func load(_ id: UUID, db: Database) throws -> MemoryItem? {
        guard let row = try Row.fetchOne(db, sql: "SELECT * FROM memory_items WHERE id=?", arguments: [id.uuidString]) else { return nil }
        let kind = MemoryKind(rawValue: row["kind"] as String)!
        let original: Original
        if kind == .text {
            original = .text(row["original_text"])
        } else {
            original = .image(path: row["original_path"], sha256: row["original_sha256"])
        }
        let confirmedValue: String? = row["confirmed_text"]
        let confirmedAt: Double? = row["confirmed_at"]
        let suggestionRow = try Row.fetchOne(db, sql: "SELECT value,status FROM ocr_suggestions WHERE item_id=?", arguments: [id.uuidString])
        let suggestion: OcrSuggestion? = suggestionRow.map {
            OcrSuggestion(value: $0["value"], status: OcrStatus(rawValue: $0["status"] as String)!)
        }
        return MemoryItem(id: id, captureID: row["capture_id"], kind: kind, original: original,
                          confirmedText: confirmedValue.flatMap { value in
                              confirmedAt.map { ConfirmedText(value: value, confirmedAt: Date(timeIntervalSince1970: $0)) }
                          }, suggestion: suggestion,
                          createdAt: Date(timeIntervalSince1970: row["created_at"]),
                          updatedAt: Date(timeIntervalSince1970: row["updated_at"]))
    }

    private func index(db: Database, id: UUID, text: String?) throws {
        try db.execute(sql: "DELETE FROM memory_fts WHERE item_id=?", arguments: [id.uuidString])
        if let text, !text.isEmpty {
            try db.execute(sql: "INSERT INTO memory_fts (item_id,confirmed_text) VALUES (?,?)",
                           arguments: [id.uuidString, text])
        }
    }
}
