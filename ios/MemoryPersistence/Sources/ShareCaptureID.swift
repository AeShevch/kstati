import CryptoKit
import Foundation

public enum ShareCaptureID {
    public static func forImage(_ data: Data) -> String {
        "share-image:" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public static func forLink(_ url: String) -> String {
        "share-link:" + SHA256.hash(data: Data(url.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
