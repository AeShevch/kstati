import Foundation

public enum MemoryError: Error, Equatable {
    case emptyText
    case emptyImage
    case missingItem
    case unavailableContainer
}
