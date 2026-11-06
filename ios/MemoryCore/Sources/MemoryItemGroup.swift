import Foundation

public struct MemoryItemGroup: Equatable, Sendable {
    public let itemID: UUID
    public let groupID: UUID
    public init(itemID: UUID, groupID: UUID) {
        self.itemID = itemID
        self.groupID = groupID
    }
}
