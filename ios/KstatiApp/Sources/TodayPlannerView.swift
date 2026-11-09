import SwiftUI

struct TodayPlannerView: View {
    @ObservedObject var store: MemoryStore

    var body: some View {
        List {
            NavigationLink("Все планы") {
                List { PlannerSection(store: store) }
                    .navigationTitle("Все планы")
            }
            PlannerSection(store: store, todayOnly: true)
        }
        .navigationTitle("Сегодня")
    }
}
