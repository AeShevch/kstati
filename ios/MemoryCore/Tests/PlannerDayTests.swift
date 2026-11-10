import Foundation
import MemoryCore
import Testing

@Test func plannerDayUsesLocalCalendarBoundary() throws {
    let utc = try #require(TimeZone(secondsFromGMT: 0))
    let east = try #require(TimeZone(secondsFromGMT: 3600))
    let date = try #require(ISO8601DateFormatter().date(from: "2026-11-09T23:30:00Z"))
    #expect(PlannerDay(date, timeZone: utc).key == 20_261_109)
    let local = PlannerDay(date, timeZone: east)
    #expect(local.key == 20_261_110)
    #expect(PlannerDay(try #require(local.date(in: east)), timeZone: east) == local)
    #expect(PlannerEntry.Schedule.event(day: local).day == local)
    #expect(PlannerEntry.Schedule.task(day: nil, completed: false).day == nil)
}
