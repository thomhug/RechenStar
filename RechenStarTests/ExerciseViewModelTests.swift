import XCTest
@testable import RechenStar

final class ExerciseViewModelTests: XCTestCase {

    private func makeSUT(
        sessionLength: Int = 10,
        categories: [ExerciseCategory] = [.addition_10, .subtraction_10]
    ) -> ExerciseViewModel {
        ExerciseViewModel(sessionLength: sessionLength, difficulty: .easy, categories: categories)
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

        XCTAssertEqual(vm.accuracy, 0.5)
    }

    func testSkipExercise() {
        let vm = makeSUT(sessionLength: 3)
        vm.startSession()
        vm.skipExercise()

        XCTAssertEqual(vm.sessionResults.count, 1)
        XCTAssertFalse(vm.sessionResults.first?.isCorrect ?? true)
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
}
