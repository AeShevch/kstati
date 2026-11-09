import UniformTypeIdentifiers

public enum SharedAttachmentSelection: Equatable {
    case link(providerIndex: Int)
    case image(providerIndex: Int)

    public static func select(_ providerTypes: [[String]]) -> Self? {
        for (index, identifiers) in providerTypes.enumerated()
        where identifiers.contains(where: {
            guard let type = UTType($0) else { return false }
            return type.conforms(to: .url) && !type.conforms(to: .fileURL)
        }) {
            return .link(providerIndex: index)
        }
        for (index, identifiers) in providerTypes.enumerated()
        where identifiers.contains(where: { UTType($0)?.conforms(to: .image) == true }) {
            return .image(providerIndex: index)
        }
        return nil
    }
}
