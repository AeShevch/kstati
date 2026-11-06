import Foundation

public struct ConfirmedText: Equatable, Sendable {
    public let value: String
    public let confirmedAt: Date
    public init(value: String, confirmedAt: Date) {
        self.value = value
        self.confirmedAt = confirmedAt
    }
}
