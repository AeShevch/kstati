import Foundation
import MemoryCore

struct MemoryExportManifest: Encodable {
    let version = 1
    let records: [Record]
    let groups: [Group]
    let memberships: [Membership]

    struct Record: Encodable {
        let id: UUID
        let kind: String
        let original: ExportOriginal
        let confirmedText: String?
        let confirmedAt: Date?
        let createdAt: Date
        let updatedAt: Date

        init(_ item: MemoryItem) {
            id = item.id
            kind = item.kind.rawValue
            original = ExportOriginal(item.original)
            confirmedText = item.confirmedText?.value
            confirmedAt = item.confirmedText?.confirmedAt
            createdAt = item.createdAt
            updatedAt = item.updatedAt
        }
    }

    struct ExportOriginal: Encodable {
        var text: String?
        var url: String?
        var path: String?
        var sha256: String?

        init(_ original: Original) {
            switch original {
            case .text(let value): text = value
            case .link(let address): url = address
            case .image(let path, let sha256):
                self.path = path
                self.sha256 = sha256
            }
        }
    }

    struct Group: Encodable {
        let id: String
        let name: String
    }

    struct Membership: Encodable {
        let itemID: String
        let groupID: String
    }
}
