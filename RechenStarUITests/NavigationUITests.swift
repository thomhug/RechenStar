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
        if app.buttons["play-button"].waitForExistence(timeout: 3) {
            return
        }

        let existingUser = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Avatar'")).firstMatch
        if existingUser.waitForExistence(timeout: 2) {
            existingUser.tap()
            _ = app.buttons["play-button"].waitForExistence(timeout: 5)
            return
        }

        let newProfile = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Neues Profil'")).firstMatch
        if newProfile.waitForExistence(timeout: 2) {
            newProfile.tap()
            let textField = app.alerts.textFields.firstMatch
            if textField.waitForExistence(timeout: 3) {
                textField.typeText("Noah")
                app.alerts.buttons["Erstellen"].tap()
            }
        }

        _ = app.buttons["play-button"].waitForExistence(timeout: 5)
    }
}
