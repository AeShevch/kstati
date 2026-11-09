import SwiftUI
import UniformTypeIdentifiers

struct MemoryExportFile: FileDocument {
    static let readableContentTypes: [UTType] = [.zip]
    let url: URL

    init(url: URL) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadUnsupportedScheme)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: url, options: [])
    }
}
