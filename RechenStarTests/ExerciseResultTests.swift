import XCTest
@testable import RechenStar

final class ExerciseResultTests: XCTestCase {

    private func makeExercise(type: OperationType = .addition, first: Int = 3, second: Int = 4) -> Exercise {
        Exercise(type: type, firstNumber: first, secondNumber: second)
    }

    func testStarsThreeOnFirstAttempt() {
        let result = ExerciseResult(
            exercise: makeExercise(),
            userAnswer: 7,
            isCorrect: true,
            attempts: 1,
            timeSpent: 5.0
        )
        XCTAssertEqual(result.stars, 3)
    }

    func testStarsTwoOnSecondAttempt() {
        let result = ExerciseResult(
            exercise: makeExercise(),
            userAnswer: 7,
            isCorrect: true,
            attempts: 2,
            timeSpent: 8.0
        )
        XCTAssertEqual(result.stars, 2)
    }

    func testStarsOneOnThirdOrMoreAttempts() {
        let result3 = ExerciseResult(
            exercise: makeExercise(),
            userAnswer: 7,
            isCorrect: true,
            attempts: 3,
            timeSpent: 12.0
        )
        XCTAssertEqual(result3.stars, 1)

        let result4 = ExerciseResult(
            exercise: makeExercise(),
            userAnswer: 7,
            isCorrect: true,
            attempts: 4,
            timeSpent: 15.0
        )
        XCTAssertEqual(result4.stars, 1)
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
