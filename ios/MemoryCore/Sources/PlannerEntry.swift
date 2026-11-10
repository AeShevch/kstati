import Foundation

public struct PlannerEntry: Equatable, Identifiable, Sendable {
    public enum Schedule: Equatable, Sendable {
        case task(day: PlannerDay?, completed: Bool)
        case event(day: PlannerDay)

        public var day: PlannerDay? {
            switch self {
            case .task(let day, _): day
            case .event(let day): day
            }
        }
    }

    public let id: UUID
    public let sourceID: UUID?
    public let title: String
    public let schedule: Schedule

    public init(id: UUID = UUID(), sourceID: UUID?, title: String, schedule: Schedule) {
        self.id = id
        self.sourceID = sourceID
        self.title = title
        self.schedule = schedule
    }
}
