import XCTest

final class ExerciseFlowUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        ensureUserExists()
    }

    // MARK: - Tests

    func testCompleteExerciseFlow() throws {
        app.buttons["play-button"].tap()

        for _ in 0..<10 {
            solveCurrentExercise()
        }

        let sessionComplete = app.descendants(matching: .any)["session-complete"].firstMatch
        XCTAssertTrue(sessionComplete.waitForExistence(timeout: 5))

        app.buttons["done-button"].tap()

        XCTAssertTrue(app.buttons["play-button"].waitForExistence(timeout: 3))
    }

    func testNumberPadInputAndDelete() throws {
        app.buttons["play-button"].tap()

        let answerDisplay = app.descendants(matching: .any)["answer-display"].firstMatch
        XCTAssertTrue(answerDisplay.waitForExistence(timeout: 5))

        app.buttons["number-pad-4"].tap()
        app.buttons["number-pad-2"].tap()

        // Verify answer shows "42"
        XCTAssertTrue(answerDisplay.label.contains("42"))

        // Delete last digit
        app.buttons["delete-button"].tap()

        // Verify answer shows "4"
        XCTAssertTrue(answerDisplay.label.contains("4"))
    }

    func testSkipExercise() throws {
        app.buttons["play-button"].tap()

        let exerciseCard = app.descendants(matching: .any)["exercise-card"].firstMatch
        XCTAssertTrue(exerciseCard.waitForExistence(timeout: 5))

        let labelBefore = exerciseCard.label

        app.buttons["skip-button"].tap()

        // Wait briefly for new exercise to load
        sleep(1)

        let labelAfter = exerciseCard.label
        XCTAssertNotEqual(labelBefore, labelAfter, "Exercise should change after skip")
    }

    func testCancelSession() throws {
        app.buttons["play-button"].tap()

        let exerciseCard = app.descendants(matching: .any)["exercise-card"].firstMatch
        XCTAssertTrue(exerciseCard.waitForExistence(timeout: 5))

        app.buttons["cancel-button"].tap()

        XCTAssertTrue(app.buttons["play-button"].waitForExistence(timeout: 3))
    }

    // MARK: - Helpers

    private func ensureUserExists() {
        let losGehts = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Los'")).firstMatch
        if losGehts.waitForExistence(timeout: 3) {
            losGehts.tap()
        }
        // Wait for home screen
        _ = app.buttons["play-button"].waitForExistence(timeout: 5)
    }

    private func solveCurrentExercise() {
        let exerciseCard = app.descendants(matching: .any)["exercise-card"].firstMatch
        guard exerciseCard.waitForExistence(timeout: 5) else {
            XCTFail("Exercise card not found")
            return
        }

        let label = exerciseCard.label
        let answer = parseAnswer(from: label)

        typeOnNumberPad(answer)

        app.buttons["submit-button"].tap()

        // Wait for auto-advance (0.6s) to move to next exercise
        sleep(1)
    }

    private func parseAnswer(from label: String) -> Int {
        // Label format: "3 + 4 gleich unbekannt" or "3 - 2 gleich unbekannt"
        let parts = label.components(separatedBy: " ")
        guard parts.count >= 3,
              let first = Int(parts[0]),
              let second = Int(parts[2]) else {
            return 0
        }

        let op = parts[1]
        switch op {
        case "+": return first + second
        case "-": return first - second
        default: return 0
        }
    }

    private func typeOnNumberPad(_ number: Int) {
        let digits = String(number)
        for char in digits {
            let digit = String(char)
            app.buttons["number-pad-\(digit)"].tap()
        }
    }
}
