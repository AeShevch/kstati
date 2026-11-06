import XCTest

@MainActor
struct MemoryListPage {
    let app: XCUIApplication

    func addMemory() -> AddMemoryPage {
        let button = app.buttons["addMemory"]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Кнопка добавления записи не появилась")
        button.tap()
        return AddMemoryPage(app: app)
    }

    func manageGroups() -> GroupsPage {
        let button = app.buttons["manageGroups"]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Кнопка групп не появилась")
        button.tap()
        return GroupsPage(app: app)
    }

    func openItem(named text: String) -> MemoryDetailPage {
        let item = app.staticTexts[text]
        XCTAssertTrue(item.waitForExistence(timeout: 10), "Запись «\(text)» не появилась")
        item.tap()
        return MemoryDetailPage(app: app)
    }

    func search(_ query: String) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Поле поиска не появилось")
        field.tap()
        if let current = field.value as? String, !current.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(query)
    }

    func item(named text: String) -> XCUIElement { app.staticTexts[text] }
    var emptyResult: XCUIElement { app.staticTexts["Ничего не найдено"] }
}
