import XCTest

final class ShareFailureE2ETests: XCTestCase {
    @MainActor
    func testShareReportsWriteFailure() {
        let session = E2ETestSession(failShareWrite: true)
        session.launch()
        let sheet = FixtureHostPage(failureImage: true).shareImage()
        sheet.save()
        XCTAssertTrue(sheet.saveError.waitForExistence(timeout: 10))
        XCTAssertFalse(sheet.saveError.label.contains("Тестовая ошибка записи"))
        XCTAssertTrue(sheet.saveButton.isEnabled)
        XCTAssertFalse(sheet.host.staticTexts["Сохранено локально"].exists)
        session.app.terminate()
        session.app.launchArguments.removeAll { $0 == "-KST_E2E_FAIL_WRITE" }
        session.app.launch()
        XCTAssertTrue(session.app.staticTexts["Пока нет записей"].waitForExistence(timeout: 10))
    }
}
