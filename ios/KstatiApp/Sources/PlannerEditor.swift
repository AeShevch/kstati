import MemoryCore
import SwiftUI

struct PlannerEditor: View {
    let store: MemoryStore
    let entry: PlannerEntry?
    let onSave: (String, PlannerEntry.Schedule) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var isEvent: Bool
    @State private var hasDate: Bool
    @State private var date: Date
    @State private var failed = false

    init(
        store: MemoryStore, entry: PlannerEntry? = nil,
        onSave: @escaping (String, PlannerEntry.Schedule) throws -> Void
    ) {
        self.store = store
        self.entry = entry
        self.onSave = onSave
        _title = State(initialValue: entry?.title ?? "")
        let event: Bool
        if case .event = entry?.schedule { event = true } else { event = false }
        _isEvent = State(initialValue: event)
        _hasDate = State(initialValue: entry == nil || entry?.schedule.day != nil)
        _date = State(initialValue: entry?.schedule.day?.date() ?? .now)
    }

    var body: some View {
        Form {
            if entry == nil {
                TextField("Заголовок", text: $title)
                    .accessibilityIdentifier("plannerTitle")
                Picker("Тип", selection: $isEvent) {
                    Text("Задача").tag(false)
                    Text("Событие").tag(true)
                }
            } else {
                Text(title)
                if let sourceID = entry?.sourceID {
                    NavigationLink("Исходная запись") { MemoryDetailView(store: store, id: sourceID) }
                }
            }
            if !isEvent {
                Toggle("Указать дату", isOn: $hasDate)
                    .accessibilityIdentifier("plannerHasDate")
            }
            if isEvent || hasDate {
                DatePicker("Дата", selection: $date, displayedComponents: .date)
                    .accessibilityIdentifier("plannerDate")
                if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) {
                    Button("Завтра") { date = tomorrow }
                        .accessibilityIdentifier("plannerTomorrow")
                }
            }
        }
        .navigationTitle(entry == nil ? "Новый план" : "Перенести план")
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Отмена") { dismiss() }.accessibilityIdentifier("cancelPlan")
                Spacer()
                Button("Сохранить") { save() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("savePlan")
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.bar)
        }
        .alert("Не удалось сохранить план", isPresented: $failed) {
            Button("ОК", role: .cancel) {}
        }
    }

    private func save() {
        let day = PlannerDay(date)
        let schedule: PlannerEntry.Schedule =
            isEvent ? .event(day: day) : .task(day: hasDate ? day : nil, completed: false)
        do {
            try onSave(title, schedule)
            dismiss()
        } catch {
            failed = true
        }
    }
}
