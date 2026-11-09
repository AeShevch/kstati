import Foundation
import ZIPFoundation

public enum MemoryArchiveExport {
    public static func prepare(from repository: MemoryRepository, in workspace: URL) throws -> URL {
        let snapshot = try repository.exportSnapshot()
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: false)
        let destination = workspace.appendingPathComponent("Кстати.zip")
        do {
            let archive = try Archive(url: destination, accessMode: .create)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let manifest = try encoder.encode(snapshot)
            try archive.addEntry(with: "manifest.json", type: .file, uncompressedSize: Int64(manifest.count)) {
                position, size in
                let start = Int(position)
                return manifest.subdata(in: start..<(start + size))
            }
            for record in snapshot.records {
                guard let path = record.original.path else { continue }
                try archive.addEntry(with: path, relativeTo: repository.directory)
            }
            return destination
        } catch {
            // The caller still owns the workspace if immediate cleanup fails.
            try? FileManager.default.removeItem(at: workspace)
            throw error
        }
    }
}
