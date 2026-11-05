import XCTest

final class KstatiUITests: XCTestCase {
    func testManualCaptureSearchAndReopen() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["addMemory"].tap()
        let editor = app.textViews["newMemoryText"]
        editor.tap()
        editor.typeText("Купить шампунь")
        app.buttons["saveMemory"].tap()
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("шампунь")
        XCTAssertTrue(app.staticTexts["Купить шампунь"].waitForExistence(timeout: 5))
        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 7))
        search.typeText("несуществующийпоиск")
        XCTAssertTrue(app.staticTexts["Ничего не найдено"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["Купить шампунь"].waitForExistence(timeout: 5))
    }
}
