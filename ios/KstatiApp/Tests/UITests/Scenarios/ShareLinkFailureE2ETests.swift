import XCTest

final class ShareLinkFailureE2ETests: XCTestCase {
    @MainActor
    func testShareLinkReportsDatabaseWriteFailure() {
        let session = E2ETestSession(failLinkWrite: true)
        session.launch()
        let sheet = FixtureHostPage().shareLink()
        sheet.save()
        XCTAssertTrue(sheet.saveError.waitForExistence(timeout: 10))
        XCTAssertTrue(sheet.saveButton.isEnabled)
        XCTAssertFalse(sheet.host.staticTexts["Сохранено локально"].exists)
        sheet.saveButton.tap()
        XCTAssertTrue(sheet.saveError.waitForExistence(timeout: 10))

        session.app.terminate()
        session.app.launchArguments.removeAll { $0 == "-KST_E2E_FAIL_LINK_WRITE" }
        session.app.launch()
        XCTAssertTrue(session.app.staticTexts["Пока нет записей"].waitForExistence(timeout: 10))
    }
}
