import XCTest

final class MemoryEditingE2ETests: XCTestCase {
    @MainActor
    func testEditKeepsOriginalAndDeletingGroupKeepsMemory() {
        let session = E2ETestSession()
        let original = "Исходная запись \(UUID().uuidString.prefix(8))"
        let corrected = "Исправленная запись \(UUID().uuidString.prefix(8))"
        let firstGroup = "Работа \(UUID().uuidString.prefix(8))"
        let secondGroup = "Личное \(UUID().uuidString.prefix(8))"
        session.launch()
        let list = MemoryListPage(app: session.app)

        let groups = list.manageGroups()
        groups.create(named: firstGroup)
        XCTAssertTrue(groups.group(named: firstGroup).waitForExistence(timeout: 5))
        groups.create(named: secondGroup)
        XCTAssertTrue(groups.group(named: secondGroup).exists)
        _ = groups.done()

        _ = list.addMemory().save(text: original)
        let detail = list.openItem(named: original)
        XCTAssertEqual(detail.originalText.label, original)

        detail.clearConfirmedText()
        XCTAssertEqual(detail.confirmedTextEditor.value as? String, "Текст")
        detail.typeConfirmedText(corrected)
        XCTAssertEqual(detail.confirmedTextEditor.value as? String, corrected)
        detail.confirmText()
        XCTAssertEqual(detail.originalText.label, original)
        XCTAssertEqual(detail.confirmedTextEditor.value as? String, corrected)

        detail.setGroup(named: firstGroup, enabled: true)
        XCTAssertEqual(detail.group(named: firstGroup).value as? String, "1")
        detail.setGroup(named: secondGroup, enabled: true)
        XCTAssertEqual(detail.group(named: secondGroup).value as? String, "1")
        _ = detail.backToList()

        list.search(corrected)
        XCTAssertTrue(list.item(named: corrected).waitForExistence(timeout: 5))
        session.relaunch()
        let reopenedList = MemoryListPage(app: session.app)
        XCTAssertTrue(reopenedList.item(named: corrected).waitForExistence(timeout: 5))
        let reopenedDetail = reopenedList.openItem(named: corrected)
        XCTAssertEqual(reopenedDetail.originalText.label, original)
        XCTAssertEqual(reopenedDetail.group(named: firstGroup).value as? String, "1")
        XCTAssertEqual(reopenedDetail.group(named: secondGroup).value as? String, "1")
        _ = reopenedDetail.backToList()

        let reopenedGroups = reopenedList.manageGroups()
        reopenedGroups.delete(named: firstGroup)
        XCTAssertFalse(reopenedGroups.group(named: firstGroup).exists)
        _ = reopenedGroups.done()
        XCTAssertTrue(reopenedList.item(named: corrected).exists)
        let afterDeletion = reopenedList.openItem(named: corrected)
        XCTAssertEqual(afterDeletion.originalText.label, original)
        XCTAssertEqual(afterDeletion.group(named: secondGroup).value as? String, "1")
    }
}
