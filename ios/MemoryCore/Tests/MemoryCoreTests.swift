import Foundation
import Testing
@testable import MemoryCore

@Test func imageKeepsOriginalSeparateFromConfirmedText() {
    let item = MemoryItem(id: UUID(), captureID: UUID().uuidString, kind: .image,
                          original: .image(path: "originals/a.png", sha256: "abc"),
                          confirmedText: nil, suggestion: nil, createdAt: Date(), updatedAt: Date())
    let edited = item.confirming("Исправлено")
    #expect(edited.original == item.original)
    #expect(edited.confirmedText?.value == "Исправлено")
}
