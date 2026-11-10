import Foundation
import MemoryCore
import MemoryPersistence
import Testing

@testable import PlannerNotifications

@MainActor
struct PlanRemindersTests {
    private final class Queue: PlanNotificationQueue {
        enum Failure: Error { case rejected }
        var status = NotificationPermission.undecided
        var grantsPermission = false
        var rejectsSchedule = false
        var requests: [String: Date] = [:]

        func permission() async -> NotificationPermission { status }
        func requestPermission() async throws -> Bool {
            status = grantsPermission ? .allowed : .denied
            return grantsPermission
        }
        func pending() async -> [String: Date] { requests }
        func schedule(_ date: Date, identifier: String) async throws {
            if rejectsSchedule { throw Failure.rejected }
            requests[identifier] = date
        }
        func remove(_ identifiers: [String]) {
            for identifier in identifiers { requests[identifier] = nil }
        }
    }

    @Test func permissionFailureReplacementAndRecovery() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = try MemoryRepository(directory: directory)
        let source = try repository.saveText("Original")
        let date = Date.now.addingTimeInterval(86_400)
        let next = date.addingTimeInterval(300)
        let entry = try repository.createPlan(
            title: "Plan", sourceID: source.id, schedule: .event(day: PlannerDay(date)))
        let queue = Queue()
        let reminders = PlanReminders(queue: queue)
        await #expect(throws: PlanReminders.Failure.denied) {
            try await reminders.set(date, for: entry, in: repository)
        }
        #expect(queue.requests.isEmpty)
        #expect(try repository.plans() == [entry])

        queue.status = .allowed
        queue.rejectsSchedule = true
        await #expect(throws: Queue.Failure.rejected) {
            try await reminders.set(date, for: entry, in: repository)
        }
        #expect(reminders.active.isEmpty)
        #expect(try repository.plans() == [entry])

        queue.rejectsSchedule = false
        try await reminders.set(date, for: entry, in: repository)
        try await reminders.set(next, for: entry, in: repository)
        let identifier = try #require(queue.requests.keys.first)
        #expect(queue.requests == [identifier: next])
        #expect(try repository.plans().first?.reminderAt == next)

        queue.requests = ["planner-reminder-stale": date, "unrelated": date]
        try await reminders.reconcile(in: repository)
        #expect(queue.requests == [identifier: next, "unrelated": date])
        try reminders.disable(entry, in: repository)
        #expect(queue.requests == ["unrelated": date])
        #expect(reminders.active.isEmpty)
        #expect(try repository.plans() == [entry])
    }
}
