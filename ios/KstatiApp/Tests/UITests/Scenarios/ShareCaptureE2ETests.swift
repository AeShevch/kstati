import XCTest

final class ShareCaptureE2ETests: XCTestCase {
    @MainActor
    func testShareImageFromAnotherApp() {
        let session = E2ETestSession()
        session.launch()
        let sheet = FixtureHostPage().shareImage()
        sheet.save()
        XCTAssertFalse(sheet.saveButton.waitForExistence(timeout: 10))

        session.app.launch()
        let list = MemoryListPage(app: session.app)
        let detail = list.openItem(named: "Изображение")
        XCTAssertTrue(detail.originalImage.waitForExistence(timeout: 5))
        XCTAssertTrue(detail.ocrSuggestion.waitForExistence(timeout: 60))
        XCTAssertTrue(detail.ocrSuggestion.label.contains("12:30"))

        let corrected = "Врач 12:30 подтверждено"
        detail.replaceConfirmedText(with: corrected)
        XCTAssertTrue(detail.originalImage.exists)
        _ = detail.backToList()

        list.search("подтверждено")
        XCTAssertTrue(list.item(named: corrected).waitForExistence(timeout: 5))
        list.search("несуществующийснимок")
        XCTAssertTrue(list.emptyResult.waitForExistence(timeout: 5))
        session.relaunch()
        let reopenedDetail = MemoryListPage(app: session.app).openItem(named: corrected)
        XCTAssertTrue(reopenedDetail.originalImage.exists)
    }
}
