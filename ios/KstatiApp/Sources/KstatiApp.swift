import SwiftUI

@main
struct KstatiApp: App {
    @StateObject private var store = MemoryStore()
    var body: some Scene {
        WindowGroup { MemoryListView(store: store) }
    }
}
