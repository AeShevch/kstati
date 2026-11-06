import Foundation
import MemoryCore
import MemoryPersistence

enum SharedMemory {
    static let groupID = "group.app.kstati.memory"
    static func repository() throws -> MemoryRepository {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            throw MemoryError.unavailableContainer
        }
        #if DEBUG
            try resetForUITestIfNeeded(in: container)
        #endif
        return try MemoryRepository(directory: container)
    }

    #if DEBUG
        private static func resetForUITestIfNeeded(in container: URL) throws {
            let arguments = ProcessInfo.processInfo.arguments
            guard let index = arguments.firstIndex(of: "-KST_E2E_TEST_ID"),
                arguments.indices.contains(index + 1),
                let id = UUID(uuidString: arguments[index + 1])
            else { return }
            let marker = container.appendingPathComponent(".kstati-e2e-test-id")
            if (try? String(contentsOf: marker, encoding: .utf8)) != id.uuidString {
                for name in [
                    "memory.sqlite", "memory.sqlite-wal", "memory.sqlite-shm", "memory.sqlite-journal", "originals",
                    ".kstati-e2e-test-id", ".kstati-e2e-fail-write",
                ] {
                    let entry = container.appendingPathComponent(name)
                    if FileManager.default.fileExists(atPath: entry.path) {
                        try FileManager.default.removeItem(at: entry)
                    }
                }
                try id.uuidString.write(to: marker, atomically: true, encoding: .utf8)
            }
            let failureMarker = container.appendingPathComponent(".kstati-e2e-fail-write")
            if arguments.contains("-KST_E2E_FAIL_WRITE") {
                try Data().write(to: failureMarker, options: .atomic)
            } else if FileManager.default.fileExists(atPath: failureMarker.path) {
                try FileManager.default.removeItem(at: failureMarker)
            }
        }
    #endif
}
