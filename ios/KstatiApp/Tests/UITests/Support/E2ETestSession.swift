import XCTest

@MainActor
struct E2ETestSession {
    let app: XCUIApplication

    init(failShareWrite: Bool = false, failLinkWrite: Bool = false) {
        app = XCUIApplication()
        app.launchArguments = ["-KST_E2E_TEST_ID", UUID().uuidString]
        if failShareWrite { app.launchArguments.append("-KST_E2E_FAIL_WRITE") }
        if failLinkWrite { app.launchArguments.append("-KST_E2E_FAIL_LINK_WRITE") }
    }

    func launch() {
        app.launch()
    }

    func relaunch() {
        app.terminate()
        app.launch()
    }
}
