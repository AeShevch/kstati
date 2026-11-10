import Foundation

public enum ReminderTime {
    public static func futureDate(
        on day: PlannerDay, hour: Int, minute: Int, now: Date = .now, timeZone: TimeZone = .current
    ) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = DateComponents(
            year: day.key / 10000, month: day.key / 100 % 100, day: day.key % 100, hour: hour, minute: minute)
        guard let date = calendar.date(from: parts), date > now,
            calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date) == parts
        else { return nil }
        return date
    }
}
