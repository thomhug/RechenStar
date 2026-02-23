import XCTest
@testable import RechenStar

final class ExerciseResultTests: XCTestCase {

    private func makeExercise(type: OperationType = .addition, first: Int = 3, second: Int = 4) -> Exercise {
        Exercise(type: type, category: type == .addition ? .addition_10 : .subtraction_10, firstNumber: first, secondNumber: second)
    }

    func testStarsTwoOnFirstAttempt() {
        let result = ExerciseResult(
            exercise: makeExercise(),
            userAnswer: 7,
            isCorrect: true,
            attempts: 1,
            timeSpent: 5.0
        )
        XCTAssertEqual(result.stars, 2)
    }

    func testStarsOneOnSecondAttempt() {
        let result = ExerciseResult(
            exercise: makeExercise(),
            userAnswer: 7,
            isCorrect: true,
            attempts: 2,
            timeSpent: 8.0
        )
        XCTAssertEqual(result.stars, 1)
    }

    func testStarsZeroWhenIncorrect() {
        let result = ExerciseResult(
            exercise: makeExercise(),
            userAnswer: 5,
            isCorrect: false,
            attempts: 1,
            timeSpent: 3.0
        )
        XCTAssertEqual(result.stars, 0)
    }

    func testCorrectAnswer() {
        let addition = makeExercise(type: .addition, first: 3, second: 4)
        XCTAssertEqual(addition.correctAnswer, 7)

        let subtraction = makeExercise(type: .subtraction, first: 8, second: 3)
        XCTAssertEqual(subtraction.correctAnswer, 5)
    }
}
