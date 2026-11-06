import Foundation
import MemoryCore
import MemoryPersistence
import Vision

public protocol TextRecognizer {
    func recognize(_ data: Data) throws -> String
}

public struct VisionTextRecognizer: TextRecognizer {
    public init() {}

    public func recognize(_ data: Data) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(data: data)
        try handler.perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}

public struct OCRProcessor<Recognizer: TextRecognizer> {
    private let recognizer: Recognizer
    public init(recognizer: Recognizer) { self.recognizer = recognizer }

    public func process(_ id: UUID, repository: MemoryRepository) throws {
        guard let data = try repository.originalData(for: id) else { throw MemoryError.missingItem }
        do {
            let text = try recognizer.recognize(data).trimmingCharacters(in: .whitespacesAndNewlines)
            try repository.setSuggestion(OcrSuggestion(value: text.isEmpty ? nil : text,
                                                        status: text.isEmpty ? .failed : .ready), for: id)
        } catch {
            try repository.setSuggestion(OcrSuggestion(value: nil, status: .failed), for: id)
        }
    }
}
