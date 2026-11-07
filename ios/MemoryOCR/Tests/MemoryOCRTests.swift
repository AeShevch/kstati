import Foundation
import MemoryCore
import MemoryPersistence
import Testing

@testable import MemoryOCR

#if canImport(AppKit)
    import AppKit
#endif

private struct FixedRecognizer: TextRecognizer {
    let result: String
    func recognize(_ data: Data) throws -> String { result }
}

private struct FailingRecognizer: TextRecognizer {
    func recognize(_ data: Data) throws -> String { throw CocoaError(.fileReadCorruptFile) }
}

@Test func ocrSuggestionDoesNotBecomeConfirmedText() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repo = try MemoryRepository(directory: directory)
    let item = try repo.saveImage(Data([1, 2, 3]), captureID: "ocr-1")
    try OCRProcessor(recognizer: FixedRecognizer(result: "Встреча")).process(item.id, repository: repo)
    #expect(try repo.item(id: item.id)?.suggestion?.value == "Встреча")
    #expect(try repo.item(id: item.id)?.confirmedText == nil)
    #expect(try repo.search("Встреча").isEmpty)
}

@Test func failedOCRKeepsOriginalAndAllowsManualText() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repo = try MemoryRepository(directory: directory)
    let bytes = Data([1, 2, 3])
    let item = try repo.saveImage(bytes, captureID: "ocr-2")
    try OCRProcessor(recognizer: FailingRecognizer()).process(item.id, repository: repo)
    #expect(try repo.item(id: item.id)?.suggestion?.status == .failed)
    try repo.confirmText("Ручное описание", for: item.id)
    #expect(try repo.originalData(for: item.id) == bytes)
}

@Test func rejectingSuggestionKeepsOriginalWithoutConfirmedText() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repo = try MemoryRepository(directory: directory)
    let bytes = Data([4, 5, 6])
    let item = try repo.saveImage(bytes, captureID: "ocr-rejected")
    try OCRProcessor(recognizer: FixedRecognizer(result: "Неверное распознавание")).process(item.id, repository: repo)
    try repo.confirmText("Подтверждение", for: item.id)
    try repo.confirmText("", for: item.id)
    #expect(try repo.item(id: item.id)?.confirmedText == nil)
    #expect(try repo.item(id: item.id)?.suggestion?.value == "Неверное распознавание")
    #expect(try repo.originalData(for: item.id) == bytes)
    #expect(try repo.search("Подтверждение").isEmpty)
}

#if canImport(AppKit)
    @Test func visionRecognizesGeneratedImageLocally() throws {
        let bitmap = try #require(
            NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: 900, pixelsHigh: 220, bitsPerSample: 8,
                samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                bytesPerRow: 0, bitsPerPixel: 0),
            "Не удалось создать bitmap для OCR-теста")
        let context = try #require(NSGraphicsContext(bitmapImageRep: bitmap), "Не удалось создать графический контекст")
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: 900, height: 220).fill()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 90, weight: .bold),
            .foregroundColor: NSColor.black,
        ]
        ("HELLO 123" as NSString).draw(at: NSPoint(x: 40, y: 55), withAttributes: attributes)
        context.flushGraphics()
        let png = try #require(bitmap.representation(using: .png, properties: [:]), "Не удалось создать PNG")
        #expect(try VisionTextRecognizer().recognize(png).contains("HELLO"))
    }
#endif
