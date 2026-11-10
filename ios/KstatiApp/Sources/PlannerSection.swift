import MemoryCore
import PlannerNotifications
import SwiftUI
import UIKit

struct PlannerSection: View {
    @ObservedObject var store: MemoryStore
    var sourceID: UUID?
    var todayOnly = false

    @Environment(\.scenePhase) private var scenePhase
    @State private var entries: [PlannerEntry] = []
    @State private var failed = false

    var body: some View {
        Section {
            if let sourceID, let repository = store.repository {
                NavigationLink("Добавить план") {
                    PlannerEditor(store: store) { title, schedule in
                        try repository.createPlan(title: title, sourceID: sourceID, schedule: schedule)
                        reload()
                    }
                }
                .accessibilityIdentifier("addPlan")
            }
            if entries.isEmpty && sourceID == nil {
                Text("Нет планов").accessibilityIdentifier("noPlans")
            }
            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    NavigationLink {
                        if let repository = store.repository {
                            PlannerEditor(store: store, entry: entry) { _, schedule in
                                let cancelID = entry.schedule.day == schedule.day ? nil : entry.id
                                try store.reminders.updatePlan(canceling: cancelID) {
                                    try repository.reschedulePlan(entry, to: schedule.day)
                                }
                                reload()
                            }
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(entry.title)
                            if let date = entry.schedule.day?.date() {
                                Text(date, format: .dateTime.day().month().year()).font(.caption)
                            } else {
                                Text("Без даты").font(.caption)
                            }
                        }
                    }
                    .buttonStyle(.borderless)
                    if case .task(_, let completed) = entry.schedule {
                        Button(completed ? "Выполнено" : "Отметить выполненной") {
                            setCompleted(entry, completed: !completed)
                        }
                        .buttonStyle(.borderless)
                    }

                }
            }
        } header: {
            if sourceID != nil { Text("Планы") }
        }
        .onAppear(perform: reload)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { reload() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in reload() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            reload()
        }
        .alert("Не удалось обновить планы", isPresented: $failed) {
            Button("ОК", role: .cancel) {}
        }
    }

    private func reload() {
        do {
            let today = PlannerDay(.now)
            entries =
                try store.repository?.plans().filter {
                    (sourceID == nil || $0.sourceID == sourceID) && (!todayOnly || $0.schedule.day == today)
                } ?? []
        } catch {
            failed = true
        }
    }

    private func setCompleted(_ entry: PlannerEntry, completed: Bool) {
        do {
            try store.reminders.updatePlan(canceling: completed ? entry.id : nil) {
                try store.repository?.setPlanCompleted(entry.id, completed: completed)
            }
            reload()
        } catch {
            failed = true
        }
    }
}
