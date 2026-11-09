import Foundation
import GRDB
import MemoryCore
import MemoryPersistence
import Testing

@Test func plannerMigrationPreservesMemoryAndPlanChangesSurviveReopen() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let text: MemoryItem
    let link: MemoryItem
    let group: MemoryGroup
    do {
        let repository = try MemoryRepository(directory: directory)
        text = try repository.saveText("Original")
        link = try repository.saveLink("https://example.com", captureID: "link")
        group = try repository.createGroup("Group")
        try repository.add(item: text.id, to: group.id)
    }
    do {
        let db = try DatabaseQueue(path: directory.appendingPathComponent("memory.sqlite").path)
        try db.write {
            try $0.execute(
                sql: """
                    DROP TABLE planner_tasks;
                    DROP TABLE planner_events;
                    DELETE FROM grdb_migrations WHERE identifier='add-planner';
                    """)
        }
    }

    let today = PlannerDay(key: 20_261_109)
    let tomorrow = PlannerDay(key: 20_261_110)
    let task: PlannerEntry
    let event: PlannerEntry
    do {
        let repository = try MemoryRepository(directory: directory)
        #expect(try repository.item(id: text.id) == text)
        #expect(try repository.item(id: link.id) == link)
        #expect(try repository.groups(for: text.id) == [group])
        task = try repository.createPlan(title: "Task", sourceID: text.id, schedule: .task(day: nil, completed: false))
        event = try repository.createPlan(title: "Event", sourceID: text.id, schedule: .event(day: today))
        try repository.setPlanCompleted(task.id, completed: true)
        try repository.reschedulePlan(task, to: tomorrow)
        try repository.reschedulePlan(event, to: tomorrow)
        #expect(try repository.item(id: text.id) == text)
        try repository.deleteItem(text.id)
    }
    let repository = try MemoryRepository(directory: directory)
    let plans = try repository.plans()
    #expect(plans.count == 2)
    #expect(plans.allSatisfy { $0.sourceID == nil })
    #expect(plans.first { $0.id == task.id }?.schedule == .task(day: tomorrow, completed: true))
    #expect(plans.first { $0.id == event.id }?.schedule == .event(day: tomorrow))
}
