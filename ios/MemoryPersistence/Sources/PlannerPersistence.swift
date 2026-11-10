import Foundation
import GRDB
import MemoryCore

extension DatabaseMigrator {
    mutating func registerPlannerMigration() {
        registerMigration("add-planner") { db in
            try db.execute(
                sql: """
                    CREATE TABLE planner_tasks (
                        id TEXT PRIMARY KEY NOT NULL,
                        source_id TEXT REFERENCES memory_items(id) ON DELETE SET NULL,
                        title TEXT NOT NULL,
                        day INTEGER,
                        completed INTEGER NOT NULL DEFAULT 0
                    );
                    CREATE TABLE planner_events (
                        id TEXT PRIMARY KEY NOT NULL,
                        source_id TEXT REFERENCES memory_items(id) ON DELETE SET NULL,
                        title TEXT NOT NULL,
                        day INTEGER NOT NULL
                    );
                    """)
        }
        registerMigration("add-local-reminders") { db in
            try db.execute(
                sql: """
                    ALTER TABLE planner_tasks ADD COLUMN reminder_at REAL;
                    ALTER TABLE planner_events ADD COLUMN reminder_at REAL;
                    """)
        }
    }
}

extension MemoryRepository {
    @discardableResult
    public func createPlan(title: String, sourceID: UUID, schedule: PlannerEntry.Schedule) throws -> PlannerEntry {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw MemoryError.emptyText }
        let entry = PlannerEntry(sourceID: sourceID, title: title, schedule: schedule)
        try dbPool.write { db in
            switch schedule {
            case .task(let day, let completed):
                try db.execute(
                    sql: "INSERT INTO planner_tasks (id,source_id,title,day,completed) VALUES (?,?,?,?,?)",
                    arguments: [entry.id.uuidString, sourceID.uuidString, title, day?.key, completed])
            case .event(let day):
                try db.execute(
                    sql: "INSERT INTO planner_events (id,source_id,title,day) VALUES (?,?,?,?)",
                    arguments: [entry.id.uuidString, sourceID.uuidString, title, day.key])
            }
        }
        return entry
    }

    public func plans() throws -> [PlannerEntry] {
        try dbPool.read { db in
            try Row.fetchAll(
                db,
                sql: """
                    SELECT * FROM (SELECT id,source_id,title,day,completed,reminder_at FROM planner_tasks
                    UNION ALL
                    SELECT id,source_id,title,day,NULL AS completed,reminder_at FROM planner_events)
                    ORDER BY day IS NULL,day,title,id
                    """
            ).map { row in
                let day = (row["day"] as Int?).map(PlannerDay.init(key:))
                let schedule: PlannerEntry.Schedule
                if let completed = row["completed"] as Bool? {
                    schedule = .task(day: day, completed: completed)
                } else if let day {
                    schedule = .event(day: day)
                } else {
                    throw MemoryError.missingItem
                }
                guard let id = UUID(uuidString: row["id"]) else { throw MemoryError.missingItem }
                return PlannerEntry(
                    id: id, sourceID: (row["source_id"] as String?).flatMap(UUID.init(uuidString:)),
                    title: row["title"], schedule: schedule,
                    reminderAt: (row["reminder_at"] as Double?).map(Date.init(timeIntervalSince1970:)))
            }
        }
    }

    public func reschedulePlan(_ entry: PlannerEntry, to day: PlannerDay?) throws {
        try dbPool.write { db in
            switch entry.schedule {
            case .task:
                try db.execute(
                    sql:
                        "UPDATE planner_tasks SET reminder_at=CASE WHEN day IS ? THEN reminder_at END, day=? WHERE id=?",
                    arguments: [day?.key, day?.key, entry.id.uuidString])
            case .event:
                guard let day else { throw MemoryError.missingItem }
                try db.execute(
                    sql:
                        "UPDATE planner_events SET reminder_at=CASE WHEN day IS ? THEN reminder_at END, day=? WHERE id=?",
                    arguments: [day.key, day.key, entry.id.uuidString])
            }
            guard db.changesCount == 1 else { throw MemoryError.missingItem }
        }
    }

    public func setPlanCompleted(_ id: UUID, completed: Bool) throws {
        try dbPool.write { db in
            try db.execute(
                sql:
                    "UPDATE planner_tasks SET reminder_at=CASE WHEN NOT ? THEN reminder_at END, completed=? WHERE id=?",
                arguments: [completed, completed, id.uuidString])
            guard db.changesCount == 1 else { throw MemoryError.missingItem }
        }
    }
    public func setPlanReminder(_ entry: PlannerEntry, at date: Date?) throws {
        try dbPool.write { db in
            let sql: String
            switch entry.schedule {
            case .task:
                sql = """
                    UPDATE planner_tasks SET reminder_at=? WHERE id=?
                    AND (? IS NULL OR (day=? AND completed=0))
                    """
            case .event:
                sql = """
                    UPDATE planner_events SET reminder_at=? WHERE id=? AND (? IS NULL OR day=?)
                    """
            }
            let timestamp = date?.timeIntervalSince1970
            try db.execute(sql: sql, arguments: [timestamp, entry.id.uuidString, timestamp, entry.schedule.day?.key])
            guard db.changesCount == 1 else { throw MemoryError.missingItem }
        }
    }
}
