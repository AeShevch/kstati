import XCTest

@MainActor
struct ShareSheetPage {
    let host: XCUIApplication

    var saveButton: XCUIElement { host.buttons["saveShareImage"] }
    var saveError: XCUIElement {
        host.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Не удалось сохранить")).firstMatch
    }

    func openKstati() {
        for _ in 0..<3 where !saveButton.waitForExistence(timeout: 2) {
            let target = host.cells["Кстати"]
            if target.exists { target.tap() }
            else { host.coordinate(withNormalizedOffset: CGVector(dx: 0.38, dy: 0.25)).tap() }
        }
        XCTAssertTrue(saveButton.waitForExistence(timeout: 10), host.debugDescription)
    }

    func save() {
        openKstati()
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: saveButton
        )
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 20), .completed, "Кнопка сохранения не стала доступной")
        saveButton.tap()
    }
}
