import Foundation
import MemoryCore
import ShareInput
import Testing
import UniformTypeIdentifiers

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

@Test func sharedAttachmentSelectionPrefersWebAddressOverPreviewImage() {
    #expect(
        SharedAttachmentSelection.select([[UTType.image.identifier, UTType.url.identifier]])
            == .link(providerIndex: 0))
    #expect(
        SharedAttachmentSelection.select([[UTType.image.identifier], [UTType.url.identifier]])
            == .link(providerIndex: 1))
    #expect(
        SharedAttachmentSelection.select([
            [UTType.fileURL.identifier, UTType.image.identifier], [UTType.url.identifier],
        ])
            == .link(providerIndex: 1))
    #expect(
        SharedAttachmentSelection.select([[UTType.image.identifier]])
            == .image(providerIndex: 0))
    #expect(
        SharedAttachmentSelection.select([[UTType.fileURL.identifier, UTType.image.identifier]])
            == .image(providerIndex: 0))
}
