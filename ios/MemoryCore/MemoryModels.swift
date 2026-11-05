import Foundation

public enum MemoryKind: String, Codable, Sendable { case text, image }

public enum Original: Equatable, Sendable {
    case text(String)
    case image(path: String, sha256: String)
}

public struct ConfirmedText: Equatable, Sendable {
    public let value: String
    public let confirmedAt: Date
    public init(value: String, confirmedAt: Date) {
        self.value = value
        self.confirmedAt = confirmedAt
    }
}

public enum OcrStatus: String, Sendable { case pending, ready, failed }

public struct OcrSuggestion: Equatable, Sendable {
    public let value: String?
    public let status: OcrStatus
    public init(value: String?, status: OcrStatus) {
        self.value = value
        self.status = status
    }
}

public struct MemoryItem: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let captureID: String
    public let kind: MemoryKind
    public let original: Original
    public let confirmedText: ConfirmedText?
    public let suggestion: OcrSuggestion?
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: UUID, captureID: String, kind: MemoryKind, original: Original,
                confirmedText: ConfirmedText?, suggestion: OcrSuggestion?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.captureID = captureID
        self.kind = kind
        self.original = original
        self.confirmedText = confirmedText
        self.suggestion = suggestion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public func confirming(_ text: String, at date: Date = .now) -> MemoryItem {
        MemoryItem(id: id, captureID: captureID, kind: kind, original: original,
                   confirmedText: ConfirmedText(value: text, confirmedAt: date),
                   suggestion: suggestion, createdAt: createdAt, updatedAt: date)
    }
}

public struct MemoryGroup: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

public struct MemoryItemGroup: Equatable, Sendable {
    public let itemID: UUID
    public let groupID: UUID
    public init(itemID: UUID, groupID: UUID) {
        self.itemID = itemID
        self.groupID = groupID
    }
}

public enum MemoryError: Error, Equatable {
    case emptyText
    case emptyImage
    case missingItem
    case unavailableContainer
}
