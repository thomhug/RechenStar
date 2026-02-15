import XCTest

final class NavigationUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        ensureUserExists()
    }

    func testTabNavigation() throws {
        let tabs = ["Spielen", "Fortschritt", "Erfolge", "Einstellungen"]

        for tabName in tabs {
            let tabButton = app.buttons["tab-\(tabName)"]
            XCTAssertTrue(tabButton.exists, "Tab '\(tabName)' should exist")
            tabButton.tap()
        }

        // Navigate back to home
        app.buttons["tab-Spielen"].tap()
        XCTAssertTrue(app.buttons["play-button"].exists)
    }

    // MARK: - Helpers

    private func ensureUserExists() {
        let losGehts = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Los'")).firstMatch
        if losGehts.waitForExistence(timeout: 3) {
            losGehts.tap()
        }
        _ = app.buttons["play-button"].waitForExistence(timeout: 5)
    }
}
