import XCTest

final class ScreenshotUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        ensureUserExists()
    }

    func testTakeAppStoreScreenshots() throws {
        // 1: Home Screen
        sleep(1)
        takeScreenshot(named: "01_home")

        // 2: Exercise Screen
        app.buttons["play-button"].tap()
        let exerciseCard = app.descendants(matching: .any)["exercise-card"].firstMatch
        XCTAssertTrue(exerciseCard.waitForExistence(timeout: 5))
        sleep(1)
        takeScreenshot(named: "02_exercise")

        // 3: Solve exercises until session complete
        let sessionComplete = app.descendants(matching: .any)["session-complete"].firstMatch
        for _ in 0..<20 {
            if sessionComplete.exists { break }
            solveCurrentExercise()
        }

        // 4: Session Complete with stars
        XCTAssertTrue(sessionComplete.waitForExistence(timeout: 10))
        sleep(1)
        takeScreenshot(named: "03_session_complete")

        // Back to home
        app.buttons["done-button"].tap()
        _ = app.buttons["play-button"].waitForExistence(timeout: 5)
        sleep(1)

        // 5: Progress tab
        app.buttons["tab-Fortschritt"].tap()
        sleep(1)
        takeScreenshot(named: "04_progress")

        // 6: Achievements tab
        app.buttons["tab-Erfolge"].tap()
        sleep(1)
        takeScreenshot(named: "05_achievements")

        // 7: Settings tab
        app.buttons["tab-Einstellungen"].tap()
        sleep(1)
        takeScreenshot(named: "06_settings")
    }

    // MARK: - Helpers

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

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

    private func solveCurrentExercise() {
        let exerciseCard = app.descendants(matching: .any)["exercise-card"].firstMatch
        guard exerciseCard.waitForExistence(timeout: 5) else { return }

        let label = exerciseCard.label
        let answer = parseAnswer(from: label)
        typeOnNumberPad(answer)
        app.buttons["submit-button"].tap()
        sleep(1)
    }

    private func parseAnswer(from label: String) -> Int {
        let parts = label.components(separatedBy: " ")
        guard parts.count >= 5 else { return 0 }

        let leftStr = parts[0]
        let op = parts[1]
        let rightStr = parts[2]
        let resultStr = parts[4]

        let left = Int(leftStr)
        let right = Int(rightStr)
        let result = Int(resultStr)

        if let l = left, let r = right {
            switch op {
            case "+": return l + r
            case "-": return l - r
            case "×": return l * r
            default: return 0
            }
        }

        if let r = right, let res = result, leftStr == "?" {
            switch op {
            case "+": return res - r
            case "-": return res + r
            case "×": return r == 0 ? 0 : res / r
            default: return 0
            }
        }

        if let l = left, let res = result, rightStr == "?" {
            switch op {
            case "+": return res - l
            case "-": return l - res
            case "×": return l == 0 ? 0 : res / l
            default: return 0
            }
        }

        return 0
    }

    private func typeOnNumberPad(_ number: Int) {
        if number < 0 {
            let negButton = app.buttons["negative-button"]
            if negButton.exists { negButton.tap() }
        }
        let digits = String(abs(number))
        for char in digits {
            app.buttons["number-pad-\(String(char))"].tap()
        }
    }
}
