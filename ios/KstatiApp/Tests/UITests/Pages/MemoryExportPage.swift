import XCTest

@MainActor
struct MemoryExportPage {
    let app: XCUIApplication

    func openPicker() {
        let export = app.buttons["exportMemory"]
        XCTAssertTrue(export.waitForExistence(timeout: 10))
        export.tap()
        let prepare = app.buttons["Подготовить архив"]
        XCTAssertTrue(prepare.waitForExistence(timeout: 5))
        prepare.tap()
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 15))
    }

    var cancelButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", ["Cancel", "Отмена"])).firstMatch
    }

    func saveOnDevice() {
        let local = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label IN %@", ["On My iPhone", "На iPhone"]))
            .firstMatch
        if local.exists && local.isHittable { local.tap() }
        let save = app.navigationBars.buttons.matching(NSPredicate(format: "label IN %@", ["Save", "Сохранить"]))
            .firstMatch
        XCTAssertTrue(save.waitForExistence(timeout: 10), app.debugDescription)
        save.tap()
        let keepBoth = app.buttons.matching(NSPredicate(format: "label IN %@", ["Keep Both", "Оставить оба"]))
            .firstMatch
        if keepBoth.exists { keepBoth.tap() }
        XCTAssertTrue(savedMessage.waitForExistence(timeout: 15), app.debugDescription)
    }

    var savedMessage: XCUIElement { app.staticTexts["Архив сохранён."] }
}
