import MemoryCore
import Testing

@Test func linkKindIsSupported() {
    #expect(MemoryKind(rawValue: "link") != nil)
    #expect(Original.link(url: "https://example.com") == .link(url: "https://example.com"))
}
