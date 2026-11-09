import XCTest

@MainActor
struct FixtureHostPage {
    let app = XCUIApplication(bundleIdentifier: "app.kstati.sharefixture")

    init(failureImage: Bool = false) {
        if failureImage { app.launchArguments = ["-failureImage"] }
    }

    func shareImage() -> ShareSheetPage {
        app.launch()
        let button = app.buttons["shareFixtureImage"]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Fixture host не показал кнопку Share")
        button.tap()
        return ShareSheetPage(host: app)
    }

    func shareLink() -> ShareSheetPage {
        app.launch()
        let button = app.buttons["shareFixtureLink"]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Fixture host не показал кнопку ссылки")
        button.tap()
        return ShareSheetPage(host: app)
    }
}
