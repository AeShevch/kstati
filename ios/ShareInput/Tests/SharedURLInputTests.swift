import Foundation
import MemoryCore
import ShareInput
import Testing

@Test func sharedURLInputAcceptsURLAndStringRepresentations() throws {
    let address = "https://example.com/article"
    #expect(try SharedURLInput.address(from: URL(string: address)!) == address)
    #expect(try SharedURLInput.address(from: address as NSString) == address)
}

@Test func sharedURLInputRejectsUnsupportedAddress() {
    #expect(throws: MemoryError.invalidURL) {
        try SharedURLInput.address(from: "file:///private/example")
    }
    #expect(throws: MemoryError.invalidURL) {
        try SharedURLInput.address(from: NSNumber(value: 42))
    }
}
