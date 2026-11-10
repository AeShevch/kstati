import MemoryCore
import MemoryPersistence
import SwiftUI

@MainActor
public final class PlanReminders: ObservableObject {
    public enum Failure: LocalizedError {
        case busy
        case denied
        case past

        public var errorDescription: String? {
            switch self {
            case .busy: "Обновление уже выполняется. Попробуйте ещё раз."
            case .past: "Выберите время в будущем."
            case .denied: "Разрешите уведомления для «Кстати» в настройках iOS."
            }
        }
    }

    @Published public private(set) var active: [UUID: Date] = [:]
    @Published public private(set) var busy = false
    private let queue: any PlanNotificationQueue

    public convenience init() { self.init(queue: SystemPlanNotificationQueue()) }

    init(queue: any PlanNotificationQueue) { self.queue = queue }
    private let prefix = "planner-reminder-"

    public func set(_ date: Date, for entry: PlannerEntry, in repository: MemoryRepository) async throws {
        guard !busy else { throw Failure.busy }
        busy = true
        defer { busy = false }
        let permission = await queue.permission()
        if permission == .undecided {
            guard try await queue.requestPermission() else { throw Failure.denied }
        } else if permission != .allowed {
            throw Failure.denied
        }
        guard date > .now else { throw Failure.past }
        try await queue.schedule(date, identifier: identifier(entry.id))
        do {
            try repository.setPlanReminder(entry, at: date)
            active[entry.id] = date
        } catch {
            cancel(entry.id)
            throw error
        }
    }

    public func disable(_ entry: PlannerEntry, in repository: MemoryRepository) throws {
        guard !busy else { throw Failure.busy }
        try repository.setPlanReminder(entry, at: nil)
        cancel(entry.id)
    }

    public func updatePlan(canceling id: UUID?, _ update: () throws -> Void) throws {
        guard !busy else { throw Failure.busy }
        try update()
        if let id { cancel(id) }
    }

    public func reconcile(in repository: MemoryRepository) async throws {
        let permission = await queue.permission()
        let requests = await queue.pending()
        guard !busy, !Task.isCancelled else { return }
        busy = true
        defer { busy = false }
        let expected = try repository.plans().compactMap { entry -> (UUID, Date)? in
            guard permission == .allowed, let date = entry.reminderAt, date > .now else { return nil }
            return (entry.id, date)
        }
        let identifiers = Set(expected.map { identifier($0.0) })
        queue.remove(
            requests.keys.filter { $0.hasPrefix(prefix) && !identifiers.contains($0) })
        var confirmed: [UUID: Date] = [:]
        var failure: (any Error)?
        for (id, date) in expected {
            do {
                if requests[identifier(id)] != date {
                    try await queue.schedule(date, identifier: identifier(id))
                }
                confirmed[id] = date
            } catch {
                failure = error
            }
        }
        active = confirmed
        if let failure { throw failure }
    }

    private func cancel(_ id: UUID) {
        queue.remove([identifier(id)])
        active[id] = nil
    }

    private func identifier(_ id: UUID) -> String { prefix + id.uuidString }
}
