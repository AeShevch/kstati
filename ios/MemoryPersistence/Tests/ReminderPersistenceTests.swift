import Foundation
import GRDB
import MemoryCore
import MemoryPersistence
import Testing

@Test func reminderMigrationAndCancellationFollowPlanChanges() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let day = PlannerDay(key: 20_261_110)
    let next = PlannerDay(key: 20_261_111)
    let reminder = try #require(day.date())
    let task: PlannerEntry
    let event: PlannerEntry
    do {
        let repo = try MemoryRepository(directory: directory)
        let source = try repo.saveText("Original")
        task = try repo.createPlan(title: "Task", sourceID: source.id, schedule: .task(day: day, completed: false))
        event = try repo.createPlan(title: "Event", sourceID: source.id, schedule: .event(day: day))
    }
    do {
        let db = try DatabaseQueue(path: directory.appendingPathComponent("memory.sqlite").path)
        try db.write {
            try $0.execute(
                sql: """
                    ALTER TABLE planner_tasks DROP COLUMN reminder_at;
                    ALTER TABLE planner_events DROP COLUMN reminder_at;
                    DELETE FROM grdb_migrations WHERE identifier='add-local-reminders';
                    """)
        }
    }
    do {
        let repo = try MemoryRepository(directory: directory)
        #expect(try repo.plans().count == 2)
        try repo.setPlanReminder(task, at: reminder)
        try repo.setPlanReminder(event, at: reminder)
    }
    let repo = try MemoryRepository(directory: directory)
    #expect(try repo.plans().allSatisfy { $0.reminderAt == reminder })
    try repo.reschedulePlan(event, to: day)
    #expect(try repo.plans().allSatisfy { $0.reminderAt == reminder })
    try repo.setPlanCompleted(task.id, completed: true)
    try repo.reschedulePlan(event, to: next)
    #expect(try repo.plans().allSatisfy { $0.reminderAt == nil })

    try repo.setPlanCompleted(task.id, completed: false)
    try repo.setPlanReminder(task, at: reminder)
    try repo.reschedulePlan(task, to: nil)
    #expect(try repo.plans().allSatisfy { $0.reminderAt == nil })
}
