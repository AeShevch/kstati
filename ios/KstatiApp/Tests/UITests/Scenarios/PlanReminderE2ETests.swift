import XCTest

final class PlanReminderE2ETests: XCTestCase {
    @MainActor
    func testReminderPersistsAndCanBeDisabled() {
        let session = E2ETestSession()
        session.launch()
        let app = session.app
        let list = MemoryListPage(app: app)
        _ = list.addMemory().save(text: "Напоминание о чае")
        _ = list.openItem(named: "Напоминание о чае")
        let planner = PlannerPage(app: app)
        planner.openEditor()
        let title = app.textFields["plannerTitle"]
        title.tap()
        title.typeText("Чай завтра")
        let tomorrow = app.buttons["plannerTomorrow"]
        if !tomorrow.isHittable { app.swipeUp() }
        tomorrow.tap()
        planner.save()

        let reminder = PlanReminderPage(app: app)
        reminder.openPlan("Чай завтра")
        reminder.schedule()
        XCTAssertTrue(reminder.active.waitForExistence(timeout: 15), app.debugDescription)

        let originalTime = reminder.active.label
        let wheel = app.pickerWheels.firstMatch
        if !wheel.isHittable { app.swipeUp() }
        XCTAssertTrue(wheel.waitForExistence(timeout: 10))
        wheel.swipeUp(velocity: .slow)
        reminder.schedule()
        let changed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", originalTime), object: reminder.active)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 15), .completed)
        let changedTime = reminder.active.label

        session.relaunch()
        _ = list.openItem(named: "Напоминание о чае")
        reminder.openPlan("Чай завтра")
        XCTAssertTrue(reminder.active.waitForExistence(timeout: 15))
        XCTAssertEqual(reminder.active.label, changedTime)
        let disable = app.buttons["disableReminder"]
        if !disable.isHittable { app.swipeUp() }
        disable.tap()
        XCTAssertTrue(app.staticTexts["Нет активного напоминания"].waitForExistence(timeout: 10))
    }
}
