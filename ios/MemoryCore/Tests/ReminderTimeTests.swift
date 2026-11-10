import Foundation
import MemoryCore
import Testing

@Test func reminderRejectsPastAndNonexistentLocalTime() throws {
    let zone = try #require(TimeZone(identifier: "Europe/Madrid"))
    let now = try #require(ISO8601DateFormatter().date(from: "2026-03-29T00:30:00Z"))
    let day = PlannerDay(key: 20_260_329)
    #expect(ReminderTime.futureDate(on: day, hour: 1, minute: 0, now: now, timeZone: zone) == nil)
    #expect(ReminderTime.futureDate(on: day, hour: 2, minute: 30, now: now, timeZone: zone) == nil)
    let expected = ISO8601DateFormatter().date(from: "2026-03-29T01:30:00Z")
    #expect(ReminderTime.futureDate(on: day, hour: 3, minute: 30, now: now, timeZone: zone) == expected)
}
