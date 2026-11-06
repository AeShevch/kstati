import Foundation

public protocol TextRecognizer {
    func recognize(_ data: Data) throws -> String
}
