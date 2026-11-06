import Foundation
import MemoryCore
import MemoryPersistence

enum SharedMemory {
    static let groupID = "group.app.kstati.memory"
    static func repository() throws -> MemoryRepository {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            throw MemoryError.unavailableContainer
        }
        return try MemoryRepository(directory: container)
    }
}
