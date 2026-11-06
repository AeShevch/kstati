import XCTest

final class ShareFailureE2ETests: XCTestCase {
    @MainActor
    func testShareReportsWriteFailure() {
        let session = E2ETestSession(failShareWrite: true)
        session.launch()
        let sheet = FixtureHostPage(failureImage: true).shareImage()
        sheet.save()
        XCTAssertTrue(sheet.saveError.waitForExistence(timeout: 10))
        XCTAssertTrue(sheet.saveButton.isEnabled)
        XCTAssertFalse(sheet.host.staticTexts["Сохранено локально"].exists)
    }
}
