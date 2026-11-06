import Foundation

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
