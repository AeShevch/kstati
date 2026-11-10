import XCTest

final class MemoryAnalysisE2ETests: XCTestCase {
    @MainActor
    func testAnalysisRequiresConsentAndExplicitPlanSave() {
        let session = E2ETestSession()
        session.launch()
        let app = session.app
        let title = "Купить синтетический чай"
        let list = MemoryListPage(app: app)
        _ = list.addMemory().save(text: title)
        let detail = list.openItem(named: title)
        let analysis = MemoryAnalysisPage(app: app)

        analysis.open()
        XCTAssertEqual(analysis.preview.label, title)
        XCTAssertFalse(analysis.suggestion.exists)
        analysis.close()

        analysis.open()
        analysis.send.tap()
        XCTAssertTrue(analysis.suggestion.waitForExistence(timeout: 20), app.debugDescription)
        analysis.suggestion.tap()
        let editor = app.textFields["plannerTitle"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        XCTAssertEqual(editor.value as? String, title)
        app.buttons["cancelPlan"].tap()
        analysis.close()
        _ = detail.backToList()

        let planner = PlannerPage(app: app)
        planner.openToday()
        XCTAssertTrue(app.staticTexts["noPlans"].waitForExistence(timeout: 10))
        session.relaunch()

        _ = list.openItem(named: title)
        analysis.open()
        analysis.send.tap()
        XCTAssertTrue(analysis.suggestion.waitForExistence(timeout: 20))
        analysis.suggestion.tap()
        planner.save()
        XCTAssertTrue(app.navigationBars["Анализ записи"].waitForExistence(timeout: 10))
        analysis.close()
        _ = detail.backToList()
        planner.openToday()
        XCTAssertTrue(planner.entry(title).waitForExistence(timeout: 10))
    }

    @MainActor
    func testAnalysisFailureKeepsOriginalAndAllowsRetry() {
        let session = E2ETestSession()
        session.launch()
        let app = session.app
        let title = "KST_FIXTURE_ANALYSIS_ERROR"
        let list = MemoryListPage(app: app)
        _ = list.addMemory().save(text: title)
        let detail = list.openItem(named: title)
        let analysis = MemoryAnalysisPage(app: app)
        analysis.open()
        analysis.send.tap()
        XCTAssertTrue(app.staticTexts["analysisError"].waitForExistence(timeout: 15))
        XCTAssertTrue(analysis.send.isEnabled)
        XCTAssertFalse(analysis.suggestion.exists)
        analysis.close()
        XCTAssertEqual(detail.originalText.label, title)
    }
}
