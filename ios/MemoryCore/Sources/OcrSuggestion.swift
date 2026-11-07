import Foundation

public enum OcrStatus: String, Sendable { case pending, ready, failed }

public struct OcrSuggestion: Equatable, Sendable {
    public let value: String?
    public let status: OcrStatus
    public init(value: String?, status: OcrStatus) {
        self.value = value
        self.status = status
    }
}
