import XCTest

@MainActor
struct AddMemoryPage {
    let app: XCUIApplication

    func save(text: String) -> MemoryListPage {
        let editor = app.textViews["newMemoryText"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10), "Редактор новой записи не появился")
        editor.tap()
        editor.typeText(text)
        app.buttons["saveMemory"].tap()
        return MemoryListPage(app: app)
    }
}
