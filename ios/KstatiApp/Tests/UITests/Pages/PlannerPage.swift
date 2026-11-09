import XCTest

@MainActor
struct PlannerPage {
    let app: XCUIApplication

    func create(title: String, undated: Bool = false) {
        openEditor()
        let field = app.textFields["plannerTitle"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(title)
        if undated {
            let toggle = app.switches["plannerHasDate"]
            XCTAssertTrue(toggle.waitForExistence(timeout: 10))
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            XCTAssertEqual(toggle.value as? String, "0")
        }
        save()
    }

    func openEditor() {
        let button = app.descendants(matching: .any).matching(identifier: "addPlan").firstMatch
        if !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.tap()
        XCTAssertTrue(app.buttons["cancelPlan"].waitForExistence(timeout: 10))
    }

    func save() {
        let button = app.buttons["savePlan"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.tap()
    }

    func openToday() {
        let link = app.descendants(matching: .any).matching(identifier: "openToday").firstMatch
        XCTAssertTrue(link.waitForExistence(timeout: 10))
        link.tap()
        XCTAssertTrue(app.navigationBars["Сегодня"].waitForExistence(timeout: 10))
    }

    func moveToTomorrow(_ title: String) {
        entry(title).tap()
        let tomorrow = app.buttons["plannerTomorrow"]
        XCTAssertTrue(tomorrow.waitForExistence(timeout: 10), app.debugDescription)
        tomorrow.tap()
        save()
    }

    func entry(_ title: String) -> XCUIElement { app.staticTexts[title] }
}
