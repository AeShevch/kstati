import XCTest

final class MemoryExportE2ETests: XCTestCase {
    @MainActor
    func testExportCanBeCancelledThenSaved() {
        let session = E2ETestSession()
        session.launch()
        let list = MemoryListPage(app: session.app)
        _ = list.addMemory().save(text: "Запись для экспорта")

        let export = MemoryExportPage(app: session.app)
        export.openPicker()
        export.cancelButton.tap()
        XCTAssertTrue(list.item(named: "Запись для экспорта").waitForExistence(timeout: 10))
        XCTAssertFalse(export.savedMessage.exists)

        export.openPicker()
        export.saveOnDevice()
    }
}
