import XCTest

final class ManualCaptureE2ETests: XCTestCase {
    @MainActor
    func testManualCaptureSearchAndReopen() {
        let session = E2ETestSession()
        session.launch()
        let list = MemoryListPage(app: session.app)
        _ = list.addMemory().save(text: "Купить шампунь")

        list.search("шампунь")
        XCTAssertTrue(list.item(named: "Купить шампунь").waitForExistence(timeout: 5))
        list.search("несуществующийпоиск")
        XCTAssertTrue(list.emptyResult.waitForExistence(timeout: 5))

        session.relaunch()
        XCTAssertTrue(MemoryListPage(app: session.app).item(named: "Купить шампунь").waitForExistence(timeout: 5))
    }
}
