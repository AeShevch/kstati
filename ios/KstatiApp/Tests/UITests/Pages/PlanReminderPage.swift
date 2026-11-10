import XCTest

@MainActor
struct PlanReminderPage {
    let app: XCUIApplication

    var active: XCUIElement { app.staticTexts["activeReminder"] }

    func openPlan(_ title: String) {
        let row = app.staticTexts[title]
        if !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
    }

    func schedule() {
        let button = app.buttons["setReminder"]
        if !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: button)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 60), .completed)
        button.tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let permission = NSPredicate(format: "label IN %@", ["Allow", "Allow Notifications", "Разрешить"])
        let allow = springboard.buttons.matching(permission).firstMatch
        if allow.waitForExistence(timeout: 10) {
            allow.tap()
        } else if !active.exists {
            XCTContext.runActivity(named: "Notification permission hierarchy") { activity in
                let attachment = XCTAttachment(string: springboard.debugDescription)
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
        }
    }
}
