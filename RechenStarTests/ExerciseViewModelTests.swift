import XCTest
@testable import RechenStar

final class ExerciseViewModelTests: XCTestCase {

    private func makeSUT(
        sessionLength: Int = 10,
        categories: [ExerciseCategory] = [.addition_10, .subtraction_10],
        metrics: ExerciseMetrics? = nil
    ) -> ExerciseViewModel {
        ExerciseViewModel(sessionLength: sessionLength, difficulty: .easy, categories: categories, metrics: metrics)
    }

    func testInitialState() {
        let vm = makeSUT()
        XCTAssertEqual(vm.sessionState, .notStarted)
        XCTAssertNil(vm.currentExercise)
        XCTAssertEqual(vm.userAnswer, "")
    }

    func testStartSession() {
        let vm = makeSUT()
        vm.startSession()
        XCTAssertEqual(vm.sessionState, .inProgress)
        XCTAssertNotNil(vm.currentExercise)
    }

    func testAppendDigit() {
        let vm = makeSUT()
        vm.startSession()
        vm.appendDigit(5)
        XCTAssertEqual(vm.userAnswer, "5")
        vm.appendDigit(3)
        XCTAssertEqual(vm.userAnswer, "53")
    }

    func testAppendDigitMaxThreeDigits() {
        let vm = makeSUT()
        vm.startSession()
        vm.appendDigit(1)
        vm.appendDigit(2)
        vm.appendDigit(3)
        XCTAssertEqual(vm.userAnswer, "123")
        vm.appendDigit(4)
        XCTAssertEqual(vm.userAnswer, "123")
    }

    func testDeleteLastDigit() {
        let vm = makeSUT()
        vm.startSession()
        vm.appendDigit(5)
        vm.appendDigit(3)
        vm.deleteLastDigit()
        XCTAssertEqual(vm.userAnswer, "5")
        vm.deleteLastDigit()
        XCTAssertEqual(vm.userAnswer, "")
    }

    func testSubmitCorrectAnswer() {
        let vm = makeSUT()
        vm.startSession()
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }
        let answer = exercise.correctAnswer
        for digit in String(answer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        XCTAssertEqual(vm.feedbackState, .correct(stars: 3))
        XCTAssertEqual(vm.sessionResults.count, 1)
        XCTAssertTrue(vm.sessionResults.first?.isCorrect == true)
    }

    func testSubmitIncorrectAnswer() {
        let vm = makeSUT()
        vm.startSession()
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }
        let wrong = (exercise.correctAnswer + 1) % 100
        for digit in String(wrong) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        XCTAssertEqual(vm.feedbackState, .incorrect)
    }

    func testSecondAttemptCorrectGivesRevenge() {
        let vm = makeSUT()
        vm.startSession()
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }

        // First attempt: wrong answer
        let wrong = (exercise.correctAnswer + 1) % 100
        for digit in String(wrong) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        XCTAssertEqual(vm.feedbackState, .incorrect)

        // Clear incorrect feedback and try again
        vm.clearIncorrectFeedback()

        // Second attempt: correct answer
        let correct = exercise.correctAnswer
        for digit in String(correct) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()

        // Should be revenge (not just correct) because it took 2 attempts
        if case .revenge(let stars) = vm.feedbackState {
            XCTAssertEqual(stars, 2) // 2nd attempt = 2 stars
        } else {
            XCTFail("Expected .revenge feedback on 2nd attempt success, got \(vm.feedbackState)")
        }
    }

    func testCanSubmit() {
        let vm = makeSUT()
        vm.startSession()
        XCTAssertFalse(vm.canSubmit)
        vm.appendDigit(5)
        XCTAssertTrue(vm.canSubmit)
    }

    func testNextExerciseAdvances() {
        let vm = makeSUT()
        vm.startSession()
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }
        let answer = exercise.correctAnswer
        for digit in String(answer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        vm.nextExercise()
        XCTAssertEqual(vm.exerciseIndex, 1)
        XCTAssertEqual(vm.userAnswer, "")
        XCTAssertEqual(vm.feedbackState, .none)
    }

    func testSessionCompletesAtEnd() {
        let vm = makeSUT(sessionLength: 2)
        vm.startSession()

        // Complete exercise 1
        let ex1 = vm.currentExercise!
        for digit in String(ex1.correctAnswer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        vm.nextExercise()

        // Complete exercise 2
        let ex2 = vm.currentExercise!
        for digit in String(ex2.correctAnswer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        vm.nextExercise()

        XCTAssertEqual(vm.sessionState, .completed)
    }

    func testProgressText() {
        let vm = makeSUT(sessionLength: 10)
        vm.startSession()
        XCTAssertEqual(vm.progressText, "1 von 10")
    }

    func testAccuracy() {
        let vm = makeSUT(sessionLength: 2)
        vm.startSession()

        // Correct answer for exercise 1
        let ex1 = vm.currentExercise!
        for digit in String(ex1.correctAnswer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        vm.nextExercise()

        // Skip exercise 2 (counts as incorrect)
        vm.skipExercise()
        vm.clearShowAnswer()

        XCTAssertEqual(vm.accuracy, 0.5)
    }

    func testSkipExercise() {
        let vm = makeSUT(sessionLength: 3)
        vm.startSession()
        let exercise = vm.currentExercise!
        vm.skipExercise()

        XCTAssertEqual(vm.sessionResults.count, 1)
        XCTAssertFalse(vm.sessionResults.first?.isCorrect ?? true)
        // Skip now shows the answer first
        XCTAssertEqual(vm.feedbackState, .showAnswer(exercise.correctAnswer))
        vm.clearShowAnswer()
        XCTAssertEqual(vm.exerciseIndex, 1)
    }

    func testNegativeToggle() {
        let vm = makeSUT(categories: [.subtraction_100])
        vm.startSession()
        XCTAssertFalse(vm.isNegative)
        vm.toggleNegative()
        XCTAssertTrue(vm.isNegative)
        vm.toggleNegative()
        XCTAssertFalse(vm.isNegative)
    }

    func testNegativeAnswerSubmission() {
        let vm = makeSUT(categories: [.subtraction_100])
        vm.startSession()
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }
        let answer = exercise.correctAnswer
        if answer < 0 {
            vm.toggleNegative()
            for digit in String(abs(answer)) {
                vm.appendDigit(Int(String(digit))!)
            }
        } else {
            for digit in String(answer) {
                vm.appendDigit(Int(String(digit))!)
            }
        }
        vm.submitAnswer()
        XCTAssertEqual(vm.feedbackState, .correct(stars: 3))
    }

    func testDisplayAnswerWithNegative() {
        let vm = makeSUT(categories: [.subtraction_100])
        vm.startSession()
        vm.appendDigit(4)
        vm.appendDigit(2)
        XCTAssertEqual(vm.displayAnswer, "42")
        vm.toggleNegative()
        XCTAssertEqual(vm.displayAnswer, "-42")
    }

    func testShowNegativeToggleOnlyForSubtraction100() {
        let vm1 = makeSUT(categories: [.subtraction_100])
        vm1.startSession()
        XCTAssertTrue(vm1.showNegativeToggle)

        let vm2 = makeSUT(categories: [.addition_10])
        vm2.startSession()
        XCTAssertFalse(vm2.showNegativeToggle)
    }

    func testNoDuplicateExercisesAfterDifficultyChange() {
        // Use a short session so adaptive difficulty triggers at exercise 3
        let vm = makeSUT(sessionLength: 10, categories: [.addition_10, .subtraction_10])
        vm.startSession()

        // Answer first 3 exercises correctly to trigger difficulty adaptation
        for _ in 0..<3 {
            guard let exercise = vm.currentExercise else {
                XCTFail("No current exercise")
                return
            }
            let answer = exercise.correctAnswer
            for digit in String(answer) {
                vm.appendDigit(Int(String(digit))!)
            }
            vm.submitAnswer()
            vm.nextExercise()
        }

        // Collect all remaining exercise signatures (after potential regeneration)
        var signatures: [String] = []
        // Include already-completed exercises
        for result in vm.sessionResults {
            signatures.append(result.exercise.signature)
        }
        // Walk remaining exercises
        var idx = vm.exerciseIndex
        while idx < vm.sessionLength && vm.sessionState == .inProgress {
            if let ex = vm.currentExercise {
                signatures.append(ex.signature)
            }
            // Skip to advance without answering (skip now shows answer first)
            vm.skipExercise()
            vm.clearShowAnswer()
            idx += 1
        }

        let unique = Set(signatures)
        XCTAssertEqual(unique.count, signatures.count,
            "Duplicate exercises found after difficulty change: \(signatures.filter { s in signatures.filter { $0 == s }.count > 1 })")
    }

    func testRevengeFeedbackOnRetryExercise() {
        // Provide metrics with weak exercises so generator produces isRetry exercises
        let metrics = ExerciseMetrics(
            categoryAccuracy: [:],
            weakExercises: [
                .addition_10: [(first: 1, second: 2), (first: 2, second: 3), (first: 3, second: 4)],
                .subtraction_10: [(first: 5, second: 2), (first: 4, second: 1)]
            ]
        )

        // Try multiple sessions since isRetry depends on 30% random chance
        var sawRevenge = false
        var sawNormalCorrect = false

        for _ in 0..<20 {
            let vm = makeSUT(sessionLength: 10, metrics: metrics)
            vm.startSession()

            for _ in 0..<10 {
                guard let exercise = vm.currentExercise else { break }
                guard vm.sessionState == .inProgress else { break }

                let answer = exercise.correctAnswer
                for digit in String(answer) {
                    vm.appendDigit(Int(String(digit))!)
                }
                vm.submitAnswer()

                if exercise.isRetry {
                    if case .revenge = vm.feedbackState {
                        sawRevenge = true
                    } else {
                        XCTFail("isRetry exercise answered correctly should give .revenge, got \(vm.feedbackState)")
                    }
                } else {
                    if case .correct = vm.feedbackState {
                        sawNormalCorrect = true
                    }
                }

                vm.nextExercise()
            }

            if sawRevenge && sawNormalCorrect { break }
        }

        XCTAssertTrue(sawRevenge, "Should have seen .revenge feedback for a retry exercise")
        XCTAssertTrue(sawNormalCorrect, "Should have seen .correct feedback for a normal exercise")
    }

    func testRevengeFeedbackOnWeakExerciseFromMetrics() {
        // All possible addition_10 pairs with easy difficulty (range 1...5)
        // so every generated exercise will match the weak list
        let allPairs = (1...5).flatMap { first in
            (1...min(5, 10 - first)).map { (first: first, second: $0) }
        }

        let metrics = ExerciseMetrics(
            categoryAccuracy: [.addition_10: 0.3],
            weakExercises: [.addition_10: allPairs]
        )

        let vm = ExerciseViewModel(
            sessionLength: 10,
            difficulty: .easy,
            categories: [.addition_10],
            metrics: metrics,
            adaptiveDifficulty: false,
            gapFillEnabled: false
        )
        vm.startSession()

        // Every exercise should trigger revenge since all pairs are weak
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }

        let answer = exercise.correctAnswer
        for digit in String(answer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()

        if case .revenge = vm.feedbackState {
            // Expected: revenge for weak exercise
        } else {
            XCTFail("Exercise matching weak list should give .revenge, got \(vm.feedbackState)")
        }
    }
}
