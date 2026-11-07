import Foundation

public enum MemoryError: Error, Equatable {
    case emptyText
    case emptyImage
    case invalidURL
    case missingItem
    case unavailableContainer
}
