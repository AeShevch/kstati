import XCTest

final class ShareLinkE2ETests: XCTestCase {
    @MainActor
    func testShareLinkSearchAndOpenAction() {
        let address = "https://example.com/article?topic=swift"
        let session = E2ETestSession()
        session.launch()
        let firstShare = FixtureHostPage().shareLink()
        firstShare.save()
        XCTAssertFalse(firstShare.saveButton.waitForExistence(timeout: 10))

        let secondShare = FixtureHostPage().shareLink()
        secondShare.save()
        XCTAssertFalse(secondShare.saveButton.waitForExistence(timeout: 10))

        session.relaunch()
        let list = MemoryListPage(app: session.app)
        list.search("example.com")
        XCTAssertEqual(
            session.app.staticTexts.matching(NSPredicate(format: "label == %@", address)).count, 1)
        let detail = list.openItem(named: address)
        XCTAssertEqual(detail.originalURL.label, address)
        XCTAssertTrue(detail.openOriginalLink.exists)
        _ = detail.backToList()
        list.search("article")
        XCTAssertTrue(list.item(named: address).waitForExistence(timeout: 5))
        let reopened = list.openItem(named: address)
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertNotEqual(safari.state, .runningForeground)
        reopened.openOriginalLink.tap()
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 10))
    }
}
