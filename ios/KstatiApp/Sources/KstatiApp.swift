import PlannerNotifications
import SwiftUI

@main
struct KstatiApp: App {
    @StateObject private var store = MemoryStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MemoryListView(store: store)
                .task(id: scenePhase) {
                    guard scenePhase == .active, let repository = store.repository else { return }
                    do {
                        try await store.reminders.reconcile(in: repository)
                    } catch {
                        store.error = "Не удалось обновить напоминания."
                    }
                }
        }
    }
}
