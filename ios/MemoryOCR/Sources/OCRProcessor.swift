import Foundation
import MemoryCore
import MemoryPersistence

public struct OCRProcessor<Recognizer: TextRecognizer> {
    private let recognizer: Recognizer
    public init(recognizer: Recognizer) { self.recognizer = recognizer }

    public func process(_ id: UUID, repository: MemoryRepository) throws {
        guard let data = try repository.originalData(for: id) else { throw MemoryError.missingItem }
        do {
            let text = try recognizer.recognize(data).trimmingCharacters(in: .whitespacesAndNewlines)
            try repository.setSuggestion(
                OcrSuggestion(
                    value: text.isEmpty ? nil : text,
                    status: text.isEmpty ? .failed : .ready), for: id)
        } catch {
            try repository.setSuggestion(OcrSuggestion(value: nil, status: .failed), for: id)
        }
    }
}
