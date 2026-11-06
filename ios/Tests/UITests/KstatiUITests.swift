import XCTest

final class KstatiUITests: XCTestCase {
    func testShareReportsWriteFailure() throws {
        guard ProcessInfo.processInfo.environment["KST_WRITE_FAILURE_TEST"] == "1" else {
            throw XCTSkip("Requires a read-only App Group originals directory")
        }
        let app = XCUIApplication()
        app.launch()
        let host = XCUIApplication(bundleIdentifier: "app.kstati.sharefixture")
        host.launchArguments = ["-failureImage"]
        host.launch()
        host.buttons["shareFixtureImage"].tap()
        let target = host.cells["Кстати"]
        if target.waitForExistence(timeout: 3) { target.tap() }
        else { host.coordinate(withNormalizedOffset: CGVector(dx: 0.38, dy: 0.25)).tap() }
        let save = host.buttons["Сохранить в Кстати"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        let ready = expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: save)
        wait(for: [ready], timeout: 20)
        save.tap()
        let error = host.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Не удалось сохранить")).firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 10), host.debugDescription)
        XCTAssertTrue(save.isEnabled)
    }

    func testShareImageFromAnotherApp() {
        let app = XCUIApplication()
        app.launch()
        let host = XCUIApplication(bundleIdentifier: "app.kstati.sharefixture")
        host.launch()
        host.buttons["shareFixtureImage"].tap()
        let save = host.buttons["Сохранить в Кстати"]
        for _ in 0..<3 where !save.waitForExistence(timeout: 2) {
            let shareTarget = host.cells["Кстати"]
            if shareTarget.exists { shareTarget.tap() }
            else { host.coordinate(withNormalizedOffset: CGVector(dx: 0.38, dy: 0.25)).tap() }
        }
        XCTAssertTrue(save.waitForExistence(timeout: 10), host.debugDescription)
        let ready = expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: save)
        wait(for: [ready], timeout: 20)
        XCTAssertTrue(save.isEnabled, host.debugDescription)
        save.tap()
        XCTAssertFalse(save.waitForExistence(timeout: 10))

        app.launch()
        XCTAssertTrue(app.staticTexts["Изображение"].waitForExistence(timeout: 10))
        app.staticTexts["Изображение"].tap()
        XCTAssertTrue(app.images["originalImage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["ocrSuggestion"].waitForExistence(timeout: 60))
        XCTAssertTrue(app.staticTexts["ocrSuggestion"].label.contains("12:30"))

        let corrected = "Врач 12:30 подтверждено"
        app.buttons["clearConfirmedText"].tap()
        let editor = app.textFields["confirmedTextEditor"]
        editor.tap()
        editor.typeText(corrected)
        app.buttons["confirmText"].tap()
        XCTAssertTrue(app.images["originalImage"].exists)
        app.navigationBars["Запись"].buttons.firstMatch.tap()

        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("подтверждено")
        XCTAssertTrue(app.staticTexts[corrected].waitForExistence(timeout: 5))
        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "подтверждено".count))
        search.typeText("несуществующийснимок")
        XCTAssertTrue(app.staticTexts["Ничего не найдено"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts[corrected].waitForExistence(timeout: 5))
        app.staticTexts[corrected].tap()
        XCTAssertTrue(app.images["originalImage"].exists)
    }

    func testEditKeepsOriginalAndDeletingGroupKeepsMemory() {
        let app = XCUIApplication()
        let original = "Исходная запись \(UUID().uuidString.prefix(8))"
        let corrected = "Исправленная запись \(UUID().uuidString.prefix(8))"
        let firstGroup = "Работа \(UUID().uuidString.prefix(8))"
        let secondGroup = "Личное \(UUID().uuidString.prefix(8))"
        app.launch()

        app.buttons["Группы"].tap()
        let groupName = app.textFields["newGroupName"]
        groupName.tap()
        groupName.typeText(firstGroup)
        app.buttons["Создать"].tap()
        XCTAssertTrue(app.staticTexts[firstGroup].waitForExistence(timeout: 5))
        groupName.tap()
        groupName.typeText(secondGroup)
        app.buttons["Создать"].tap()
        XCTAssertTrue(app.staticTexts[secondGroup].exists)
        app.buttons["Готово"].tap()

        app.buttons["addMemory"].tap()
        let newMemory = app.textViews["newMemoryText"]
        newMemory.tap()
        newMemory.typeText(original)
        app.buttons["saveMemory"].tap()
        app.staticTexts[original].tap()
        XCTAssertEqual(app.staticTexts["originalText"].label, original)

        let editor = app.textFields["confirmedTextEditor"]
        app.buttons["clearConfirmedText"].tap()
        XCTAssertEqual(editor.value as? String, "Текст")
        editor.tap()
        editor.typeText(corrected)
        XCTAssertEqual(editor.value as? String, corrected)
        app.buttons["confirmText"].tap()
        XCTAssertEqual(app.staticTexts["originalText"].label, original)
        XCTAssertEqual(app.textFields["confirmedTextEditor"].value as? String, corrected)

        app.switches[firstGroup].coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(app.switches[firstGroup].value as? String, "1")
        app.switches[secondGroup].coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(app.switches[secondGroup].value as? String, "1")
        app.navigationBars["Запись"].buttons.firstMatch.tap()

        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText(corrected)
        XCTAssertTrue(app.staticTexts[corrected].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts[corrected].waitForExistence(timeout: 5))
        app.staticTexts[corrected].tap()
        XCTAssertEqual(app.staticTexts["originalText"].label, original)
        XCTAssertEqual(app.switches[firstGroup].value as? String, "1")
        XCTAssertEqual(app.switches[secondGroup].value as? String, "1")
        app.navigationBars["Запись"].buttons.firstMatch.tap()

        app.buttons["Группы"].tap()
        app.buttons["Удалить группу \(firstGroup)"].tap()
        XCTAssertFalse(app.staticTexts[firstGroup].exists)
        app.buttons["Готово"].tap()
        XCTAssertTrue(app.staticTexts[corrected].exists)
        app.staticTexts[corrected].tap()
        XCTAssertEqual(app.staticTexts["originalText"].label, original)
        XCTAssertEqual(app.switches[secondGroup].value as? String, "1")
    }

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
