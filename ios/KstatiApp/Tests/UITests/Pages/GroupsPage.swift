import XCTest

@MainActor
struct GroupsPage {
    let app: XCUIApplication

    func create(named name: String) {
        let field = app.textFields["newGroupName"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Поле названия группы не появилось")
        field.tap()
        field.typeText(name)
        app.buttons["createGroup"].tap()
    }

    func delete(named name: String) {
        let button = app.buttons["Удалить группу \(name)"]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Кнопка удаления группы «\(name)» не появилась")
        button.tap()
    }

    func group(named name: String) -> XCUIElement { app.staticTexts[name] }

    func done() -> MemoryListPage {
        app.buttons["doneGroups"].tap()
        return MemoryListPage(app: app)
    }
}
