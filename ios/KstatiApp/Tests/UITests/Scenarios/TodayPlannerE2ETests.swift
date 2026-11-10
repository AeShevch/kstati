import XCTest

final class TodayPlannerE2ETests: XCTestCase {
    @MainActor
    func testCreateCompleteAndMovePlan() {
        let session = E2ETestSession()
        session.launch()
        let app = session.app
        let list = MemoryListPage(app: app)
        _ = list.addMemory().save(text: "Купить чай")
        _ = list.openItem(named: "Купить чай")

        let planner = PlannerPage(app: app)
        planner.openEditor()
        app.buttons["cancelPlan"].tap()
        planner.create(title: "Чай на сегодня")
        planner.create(title: "Чай без даты", undated: true)
        XCTAssertTrue(planner.entry("Чай без даты").waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["originalText"].label, "Купить чай")

        session.relaunch()
        planner.openToday()
        XCTAssertTrue(planner.entry("Чай на сегодня").waitForExistence(timeout: 10))
        XCTAssertFalse(planner.entry("Чай без даты").exists)
        app.buttons["Отметить выполненной"].tap()
        XCTAssertTrue(app.buttons["Выполнено"].waitForExistence(timeout: 10))
        planner.moveToTomorrow("Чай на сегодня")
        XCTAssertTrue(app.staticTexts["noPlans"].waitForExistence(timeout: 10))

        session.relaunch()
        planner.openToday()
        XCTAssertTrue(app.staticTexts["noPlans"].waitForExistence(timeout: 10))
        app.staticTexts["Все планы"].tap()
        XCTAssertTrue(planner.entry("Чай на сегодня").waitForExistence(timeout: 10))
        XCTAssertTrue(planner.entry("Чай без даты").exists)
        XCTAssertTrue(app.buttons["Выполнено"].exists)
    }
}
