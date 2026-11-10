import Foundation
import UserNotifications

@MainActor
protocol PlanNotificationQueue {
    func permission() async -> NotificationPermission
    func requestPermission() async throws -> Bool
    func pending() async -> [String: Date]
    func schedule(_ date: Date, identifier: String) async throws
    func remove(_ identifiers: [String])
}

enum NotificationPermission {
    case undecided
    case denied
    case allowed
}

@MainActor
struct SystemPlanNotificationQueue: PlanNotificationQueue {
    private let center = UNUserNotificationCenter.current()

    func permission() async -> NotificationPermission {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined { return .undecided }
        return settings.alertSetting == .enabled && settings.authorizationStatus != .denied ? .allowed : .denied
    }

    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func pending() async -> [String: Date] {
        let requests = await center.pendingNotificationRequests()
        var dates: [String: Date] = [:]
        for request in requests {
            let trigger = request.trigger as? UNCalendarNotificationTrigger
            dates[request.identifier] = trigger?.nextTriggerDate() ?? .distantPast
        }
        return dates
    }

    func schedule(_ date: Date, identifier: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Напоминание о плане"
        content.body = "Откройте «Кстати», чтобы посмотреть план."
        content.sound = .default
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        parts.timeZone = .gmt
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    func remove(_ identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
