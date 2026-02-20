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

        // Wait for answer display (2.5s) + next exercise load
        sleep(4)

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

    func testDifficultySettingAffectsExercises() throws {
        // Navigate to Settings
        app.buttons["tab-Einstellungen"].firstMatch.tap()

        // Tap the difficulty picker (has accessibilityIdentifier)
        let difficultyPicker = app.buttons["difficulty-picker"].firstMatch
        XCTAssertTrue(difficultyPicker.waitForExistence(timeout: 5), "Difficulty picker should exist")
        difficultyPicker.tap()

        // Select "Schwer" from the popup menu
        let schwerOption = app.buttons["Schwer"].firstMatch
        XCTAssertTrue(schwerOption.waitForExistence(timeout: 3), "Schwer option should appear")
        schwerOption.tap()

        // Small delay to let the picker menu dismiss
        sleep(1)

        // Navigate back to Home
        app.buttons["tab-Spielen"].firstMatch.tap()
        XCTAssertTrue(app.buttons["play-button"].waitForExistence(timeout: 5))

        // Start session
        app.buttons["play-button"].tap()

        // Check exercises: with hard difficulty (range 1...10), we should
        // see at least one number > 5 across 10 exercises
        var sawLargeNumber = false

        for _ in 0..<10 {
            let exerciseCard = app.descendants(matching: .any)["exercise-card"].firstMatch
            guard exerciseCard.waitForExistence(timeout: 5) else {
                XCTFail("Exercise card not found")
                return
            }

            let label = exerciseCard.label
            let parts = label.components(separatedBy: " ")
            if let first = Int(parts[0]), first > 5 { sawLargeNumber = true }
            if parts.count >= 3, let second = Int(parts[2]), second > 5 { sawLargeNumber = true }

            solveCurrentExercise()
        }

        XCTAssertTrue(sawLargeNumber,
            "With hard difficulty, at least one number should be > 5 (range 1...10)")

        // Dismiss session complete
        let sessionComplete = app.descendants(matching: .any)["session-complete"].firstMatch
        if sessionComplete.waitForExistence(timeout: 5) {
            app.buttons["done-button"].tap()
        }
    }

    func testEasyDifficultyLimitsNumbers() throws {
        // Navigate to Settings
        app.buttons["tab-Einstellungen"].firstMatch.tap()

        // Set difficulty to "Leicht"
        let difficultyPicker = app.buttons["difficulty-picker"].firstMatch
        XCTAssertTrue(difficultyPicker.waitForExistence(timeout: 5), "Difficulty picker should exist")
        difficultyPicker.tap()

        let leichtOption = app.buttons["Leicht"].firstMatch
        XCTAssertTrue(leichtOption.waitForExistence(timeout: 3), "Leicht option should appear")
        leichtOption.tap()

        sleep(1)

        // Navigate to Home and start session
        app.buttons["tab-Spielen"].firstMatch.tap()
        XCTAssertTrue(app.buttons["play-button"].waitForExistence(timeout: 5))
        app.buttons["play-button"].tap()

        // With easy difficulty (range 1...5), ALL numbers must be <= 5
        for i in 0..<10 {
            let exerciseCard = app.descendants(matching: .any)["exercise-card"].firstMatch
            guard exerciseCard.waitForExistence(timeout: 5) else {
                XCTFail("Exercise card not found")
                return
            }

            let label = exerciseCard.label
            let parts = label.components(separatedBy: " ")
            if let first = Int(parts[0]) {
                XCTAssertLessThanOrEqual(first, 5,
                    "Exercise \(i+1): first number \(first) exceeds easy range (max 5) — \(label)")
            }
            if parts.count >= 3, let second = Int(parts[2]) {
                XCTAssertLessThanOrEqual(second, 5,
                    "Exercise \(i+1): second number \(second) exceeds easy range (max 5) — \(label)")
            }

            solveCurrentExercise()
        }

        // Dismiss session complete
        let sessionComplete = app.descendants(matching: .any)["session-complete"].firstMatch
        if sessionComplete.waitForExistence(timeout: 5) {
            app.buttons["done-button"].tap()
        }
    }

    func testRevengeOnSecondAttempt() throws {
        app.buttons["play-button"].tap()

        let exerciseCard = app.descendants(matching: .any)["exercise-card"].firstMatch
        XCTAssertTrue(exerciseCard.waitForExistence(timeout: 5))

        let label = exerciseCard.label
        let correctAnswer = parseAnswer(from: label)

        // Submit a wrong answer first
        let wrongAnswer = correctAnswer == 0 ? 1 : 0
        typeOnNumberPad(wrongAnswer)
        app.buttons["submit-button"].tap()

        // Wait for incorrect feedback to clear (1s auto-clear)
        sleep(2)

        // Now submit the correct answer
        typeOnNumberPad(correctAnswer)
        app.buttons["submit-button"].tap()

        // Verify revenge feedback appears
        let revengeFeedback = app.descendants(matching: .any)["revenge-feedback"].firstMatch
        XCTAssertTrue(revengeFeedback.waitForExistence(timeout: 3),
            "Revenge feedback ('Stark! Du hast es geschafft!') should appear on 2nd attempt success")

        // Wait for auto-advance (1.5s for revenge)
        sleep(2)

        // Verify session continues to next exercise
        let newLabel = exerciseCard.label
        XCTAssertNotEqual(label, newLabel, "Should have advanced to next exercise after revenge")
    }

    func testRevengeVsNormalFeedbackInSession() throws {
        // Tests multiple exercises in ONE session:
        // - First-attempt correct → normal checkmark (no revenge)
        // - Wrong then correct → revenge stars
        // - Another first-attempt correct → normal checkmark again
        app.buttons["play-button"].tap()

        let exerciseCard = app.descendants(matching: .any)["exercise-card"].firstMatch
        let revengeFeedback = app.descendants(matching: .any)["revenge-feedback"].firstMatch
        XCTAssertTrue(exerciseCard.waitForExistence(timeout: 5))

        // --- Exercise 1: Solve correctly on first attempt → NO revenge ---
        let label1 = exerciseCard.label
        let answer1 = parseAnswer(from: label1)
        typeOnNumberPad(answer1)
        app.buttons["submit-button"].tap()

        // Revenge should NOT appear for first-attempt correct
        XCTAssertFalse(revengeFeedback.waitForExistence(timeout: 1),
            "Exercise 1: First-attempt correct should NOT show revenge stars (\(label1), answered \(answer1))")
        sleep(2) // wait for auto-advance

        // --- Exercise 2: Wrong first, correct second → REVENGE ---
        XCTAssertTrue(exerciseCard.waitForExistence(timeout: 5))
        let label2 = exerciseCard.label
        let answer2 = parseAnswer(from: label2)

        // Pick a definitely wrong answer
        let wrong2 = (answer2 + 1) % 100
        typeOnNumberPad(wrong2)
        app.buttons["submit-button"].tap()
        sleep(2) // wait for incorrect feedback to clear

        typeOnNumberPad(answer2)
        app.buttons["submit-button"].tap()

        XCTAssertTrue(revengeFeedback.waitForExistence(timeout: 3),
            "Exercise 2: Second-attempt correct should show revenge stars (\(label2), wrong=\(wrong2), correct=\(answer2))")
        sleep(3) // wait for revenge auto-advance (1.5s)

        // --- Exercise 3: Solve correctly on first attempt again → NO revenge ---
        XCTAssertTrue(exerciseCard.waitForExistence(timeout: 5))
        let label3 = exerciseCard.label
        let answer3 = parseAnswer(from: label3)
        typeOnNumberPad(answer3)
        app.buttons["submit-button"].tap()

        XCTAssertFalse(revengeFeedback.waitForExistence(timeout: 1),
            "Exercise 3: First-attempt correct should NOT show revenge stars (\(label3), answered \(answer3))")
    }

    func testRevengeWorksAcrossMultipleSessions() throws {
        // Session 1: Wrong then correct → revenge
        app.buttons["play-button"].tap()

        let exerciseCard = app.descendants(matching: .any)["exercise-card"].firstMatch
        let revengeFeedback = app.descendants(matching: .any)["revenge-feedback"].firstMatch
        XCTAssertTrue(exerciseCard.waitForExistence(timeout: 5))

        let label1 = exerciseCard.label
        let answer1 = parseAnswer(from: label1)
        let wrong1 = (answer1 + 1) % 100
        typeOnNumberPad(wrong1)
        app.buttons["submit-button"].tap()
        sleep(2)
        typeOnNumberPad(answer1)
        app.buttons["submit-button"].tap()

        XCTAssertTrue(revengeFeedback.waitForExistence(timeout: 3),
            "Session 1: Revenge should appear on 2nd attempt (\(label1))")
        sleep(3)

        // Cancel session 1
        app.buttons["cancel-button"].tap()
        XCTAssertTrue(app.buttons["play-button"].waitForExistence(timeout: 5))

        // Session 2: Wrong then correct → revenge should still work
        app.buttons["play-button"].tap()
        XCTAssertTrue(exerciseCard.waitForExistence(timeout: 5))

        let label2 = exerciseCard.label
        let answer2 = parseAnswer(from: label2)
        let wrong2 = (answer2 + 1) % 100
        typeOnNumberPad(wrong2)
        app.buttons["submit-button"].tap()
        sleep(2)
        typeOnNumberPad(answer2)
        app.buttons["submit-button"].tap()

        XCTAssertTrue(revengeFeedback.waitForExistence(timeout: 3),
            "Session 2: Revenge should still appear on 2nd attempt in a new session (\(label2))")
    }

    // MARK: - Helpers

    private func ensureUserExists() {
        // If play button already visible, we're on home screen
        if app.buttons["play-button"].waitForExistence(timeout: 3) {
            return
        }

        // Check if there's an existing user profile to tap
        let existingUser = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Avatar'")).firstMatch
        if existingUser.waitForExistence(timeout: 2) {
            existingUser.tap()
            _ = app.buttons["play-button"].waitForExistence(timeout: 5)
            return
        }

        // No user exists - create one
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
        guard exerciseCard.waitForExistence(timeout: 5) else {
            XCTFail("Exercise card not found")
            return
        }

        let label = exerciseCard.label
        let answer = parseAnswer(from: label)

        typeOnNumberPad(answer)

        app.buttons["submit-button"].tap()

        // Wait for star animation + auto-advance (1.0s)
        sleep(2)
    }

    private func parseAnswer(from label: String) -> Int {
        // Label formats:
        // Standard:   "3 + 4 gleich unbekannt"  → answer = 3+4 = 7
        // FirstGap:   "? + 4 gleich 7"          → answer = 7-4 = 3
        // SecondGap:  "3 + ? gleich 7"          → answer = 7-3 = 4
        let parts = label.components(separatedBy: " ")
        guard parts.count >= 5 else { return 0 }

        let leftStr = parts[0]
        let op = parts[1]
        let rightStr = parts[2]
        // parts[3] == "gleich"
        let resultStr = parts[4]

        let left = Int(leftStr)
        let right = Int(rightStr)
        let result = Int(resultStr)

        // Standard format: left and right are numbers, result is "unbekannt"
        if let l = left, let r = right {
            switch op {
            case "+": return l + r
            case "-": return l - r
            case "×": return l * r
            default: return 0
            }
        }

        // Gap-fill: one side is "?", result is a number
        if let r = right, let res = result, leftStr == "?" {
            // FirstGap: ? op right = result → answer is the missing left
            switch op {
            case "+": return res - r
            case "-": return res + r
            case "×": return r == 0 ? 0 : res / r
            default: return 0
            }
        }

        if let l = left, let res = result, rightStr == "?" {
            // SecondGap: left op ? = result → answer is the missing right
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
            let digit = String(char)
            app.buttons["number-pad-\(digit)"].tap()
        }
    }
}
