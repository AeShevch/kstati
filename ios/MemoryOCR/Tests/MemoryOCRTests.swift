import Foundation
import MemoryCore
import MemoryPersistence
import Testing

@testable import MemoryOCR

#if canImport(CoreGraphics) && canImport(CoreText) && canImport(ImageIO)
    import CoreGraphics
    import CoreText
    import ImageIO
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

#if canImport(CoreGraphics) && canImport(CoreText) && canImport(ImageIO)
    @Test(
        .disabled(
            if: ProcessInfo.processInfo.environment["KSTATI_SKIP_HOSTED_MACOS_VISION_TEST"] == "1",
            "Vision returns nilError on the hosted macOS runner; Smoke E2E checks OCR in iOS Simulator"))
    func visionRecognizesGeneratedImageLocally() throws {
        guard
            let context = CGContext(
                data: nil, width: 900, height: 220, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else {
            Issue.record("CGContext creation failed")
            return
        }
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 900, height: 220))
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 90, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(
                red: 0, green: 0, blue: 0, alpha: 1),
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: "HELLO 123", attributes: attributes))
        context.textPosition = CGPoint(x: 40, y: 55)
        CTLineDraw(line, context)
        guard let image = context.makeImage() else {
            Issue.record("CGImage creation failed")
            return
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, "public.png" as CFString, 1, nil)
        else {
            Issue.record("PNG destination creation failed")
            return
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            Issue.record("PNG encoding failed")
            return
        }
        let png = output as Data
        do {
            #expect(try VisionTextRecognizer().recognize(png).contains("HELLO"))
        } catch {
            Issue.record("Vision recognition failed: \(type(of: error)): \(error)")
        }
    }
#endif
