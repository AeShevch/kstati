import Foundation

public enum Original: Equatable, Sendable {
    case text(String)
    case image(path: String, sha256: String)
}
