import XCTest

@MainActor
struct MemoryDetailPage {
    let app: XCUIApplication

    var originalImage: XCUIElement { app.images["originalImage"] }
    var originalText: XCUIElement { app.staticTexts["originalText"] }
    var originalURL: XCUIElement { app.staticTexts["originalURL"] }
    var openOriginalLink: XCUIElement { app.links["openOriginalLink"] }
    var ocrSuggestion: XCUIElement { app.staticTexts["ocrSuggestion"] }
    var confirmedTextEditor: XCUIElement { app.textFields["confirmedTextEditor"] }

    func clearConfirmedText() {
        let clear = app.buttons["clearConfirmedText"]
        XCTAssertTrue(clear.waitForExistence(timeout: 10), "Кнопка очистки текста не появилась")
        clear.tap()
    }

    func typeConfirmedText(_ text: String) {
        confirmedTextEditor.tap()
        confirmedTextEditor.typeText(text)
    }

    func confirmText() {
        app.buttons["confirmText"].tap()
    }

    func replaceConfirmedText(with text: String) {
        clearConfirmedText()
        typeConfirmedText(text)
        confirmText()
    }

    func setGroup(named name: String, enabled: Bool) {
        let toggle = app.switches[name]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "Группа «\(name)» не появилась в карточке")
        if (toggle.value as? String == "1") != enabled {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
    }

    func group(named name: String) -> XCUIElement { app.switches[name] }

    func backToList() -> MemoryListPage {
        let button = app.navigationBars["Запись"].buttons.firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Кнопка возврата из карточки не появилась")
        button.tap()
        return MemoryListPage(app: app)
    }
}
