import XCTest

@MainActor
struct MemoryAnalysisPage {
    let app: XCUIApplication

    func open() {
        let link = app.buttons["openAnalysis"]
        if !link.isHittable { app.swipeUp() }
        XCTAssertTrue(link.waitForExistence(timeout: 10))
        link.tap()
        XCTAssertTrue(app.staticTexts["analysisPreview"].waitForExistence(timeout: 10))
    }

    var preview: XCUIElement { app.staticTexts["analysisPreview"] }
    var send: XCUIElement { app.buttons["confirmAnalysis"] }
    var suggestion: XCUIElement { app.buttons["analysisSuggestion-0"] }

    func close() {
        let button = app.buttons["closeAnalysis"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.tap()
    }
}
