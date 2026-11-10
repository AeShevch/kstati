import MemoryCore
import MemoryPersistence
import PlannerNotifications
import SwiftUI

struct PlanReminderControls: View {
    @ObservedObject var reminders: PlanReminders
    let repository: MemoryRepository
    let entry: PlannerEntry
    let day: PlannerDay

    @State private var time: Date
    @State private var errorMessage: String?
    @State private var configured: Bool

    init(reminders: PlanReminders, repository: MemoryRepository, entry: PlannerEntry, day: PlannerDay) {
        self.reminders = reminders
        self.repository = repository
        self.entry = entry
        self.day = day
        _time = State(initialValue: entry.reminderAt ?? .now.addingTimeInterval(3600))
        _configured = State(initialValue: entry.reminderAt != nil)
    }

    var body: some View {
        Section("Напоминание") {
            Text("Уведомление о плане «\(entry.title)».")
            if let active = reminders.active[entry.id], active > .now {
                Text(active, format: .dateTime.day().month().hour().minute())
                    .accessibilityIdentifier("activeReminder")
            } else {
                Text("Нет активного напоминания")
            }
            DatePicker("Время", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
            Button("Установить напоминание") { Task { await schedule() } }
                .accessibilityIdentifier("setReminder")
            if configured {
                Button("Выключить напоминание", role: .destructive) { disable() }
                    .accessibilityIdentifier("disableReminder")
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).accessibilityIdentifier("reminderError")
            }
        }
        .disabled(reminders.busy)
    }

    private func schedule() async {
        errorMessage = nil
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        guard let hour = parts.hour, let minute = parts.minute,
            let date = ReminderTime.futureDate(on: day, hour: hour, minute: minute)
        else {
            errorMessage = "Выберите доступное время в будущем."
            return
        }
        do {
            try await reminders.set(date, for: entry, in: repository)
            configured = true
        } catch let failure as PlanReminders.Failure {
            errorMessage = failure.errorDescription
        } catch {
            errorMessage = "Не удалось установить напоминание. Попробуйте ещё раз."
        }
    }

    private func disable() {
        errorMessage = nil
        do {
            try reminders.disable(entry, in: repository)
            configured = false
        } catch {
            errorMessage = "Не удалось выключить напоминание. Попробуйте ещё раз."
        }
    }
}
