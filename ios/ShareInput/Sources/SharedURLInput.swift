import Foundation
import MemoryCore

public enum SharedURLInput {
    public static func address(from item: Any) throws -> String {
        let address: String
        if let url = item as? URL {
            address = url.absoluteString
        } else if let string = item as? String {
            address = string
        } else {
            throw MemoryError.invalidURL
        }
        guard let components = URLComponents(string: address),
            let scheme = components.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            let host = components.host, !host.isEmpty
        else { throw MemoryError.invalidURL }
        return address
    }
}
