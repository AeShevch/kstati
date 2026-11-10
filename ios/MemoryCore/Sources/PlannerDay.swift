import Foundation

public struct PlannerDay: Equatable, Comparable, Sendable {
    public let key: Int

    public init(_ date: Date, timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        key = (parts.year ?? 1) * 10000 + (parts.month ?? 1) * 100 + (parts.day ?? 1)
    }

    public init(key: Int) {
        self.key = key
    }

    public func date(in timeZone: TimeZone = .current) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(
            from: DateComponents(year: key / 10000, month: key / 100 % 100, day: key % 100, hour: 12))
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.key < rhs.key }
}
