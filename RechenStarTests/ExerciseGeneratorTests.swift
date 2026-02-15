import XCTest
@testable import RechenStar

final class ExerciseGeneratorTests: XCTestCase {

    func testGenerateReturnsValidExercise() {
        let exercise = ExerciseGenerator.generate(difficulty: .easy)
        XCTAssertGreaterThanOrEqual(exercise.correctAnswer, 0)
        XCTAssertGreaterThanOrEqual(exercise.firstNumber, 1)
        XCTAssertGreaterThanOrEqual(exercise.secondNumber, 1)
    }

    func testAdditionNeverExceedsTen() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .hard,
                operationType: .addition
            )
            XCTAssertLessThanOrEqual(
                exercise.firstNumber + exercise.secondNumber, 10,
                "Addition \(exercise.firstNumber) + \(exercise.secondNumber) exceeds 10"
            )
        }
    }

    func testSubtractionNeverNegative() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .hard,
                operationType: .subtraction
            )
            XCTAssertGreaterThanOrEqual(
                exercise.firstNumber - exercise.secondNumber, 0,
                "Subtraction \(exercise.firstNumber) - \(exercise.secondNumber) is negative"
            )
        }
    }

    func testDifficultyRanges() {
        let cases: [(Difficulty, Int, Int)] = [
            (.veryEasy, 1, 3),
            (.easy, 1, 5),
            (.medium, 1, 7),
            (.hard, 1, 10),
        ]

        for (difficulty, lower, upper) in cases {
            for _ in 0..<50 {
                let exercise = ExerciseGenerator.generate(difficulty: difficulty)
                XCTAssertGreaterThanOrEqual(exercise.firstNumber, lower)
                XCTAssertLessThanOrEqual(exercise.firstNumber, upper)
                XCTAssertGreaterThanOrEqual(exercise.secondNumber, lower)
                XCTAssertLessThanOrEqual(exercise.secondNumber, upper)
            }
        }
    }

    func testGenerateSessionCorrectCount() {
        let exercises = ExerciseGenerator.generateSession(count: 10, difficulty: .easy)
        XCTAssertEqual(exercises.count, 10)
    }

    func testGenerateSessionNoDuplicates() {
        let exercises = ExerciseGenerator.generateSession(count: 10, difficulty: .hard)
        let signatures = exercises.map(\.signature)
        let unique = Set(signatures)
        XCTAssertEqual(unique.count, signatures.count, "Duplicate signatures found")
    }

    func testExcludingSignaturesRespected() {
        let excluded: Set<String> = ["plus_1_2", "plus_3_4"]
        for _ in 0..<50 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .easy,
                operationType: .addition,
                excluding: excluded
            )
            XCTAssertFalse(excluded.contains(exercise.signature))
        }
    }

    func testAdaptDifficultyUp() {
        let result = ExerciseGenerator.adaptDifficulty(current: .easy, recentAccuracy: 0.9)
        XCTAssertEqual(result, .medium)
    }

    func testAdaptDifficultyDown() {
        let result = ExerciseGenerator.adaptDifficulty(current: .medium, recentAccuracy: 0.4)
        XCTAssertEqual(result, .easy)
    }

    func testAdaptDifficultyStays() {
        let result = ExerciseGenerator.adaptDifficulty(current: .easy, recentAccuracy: 0.7)
        XCTAssertEqual(result, .easy)
    }

    func testAdaptDifficultyHardCeiling() {
        let result = ExerciseGenerator.adaptDifficulty(current: .hard, recentAccuracy: 1.0)
        XCTAssertEqual(result, .hard)
    }

    func testAdaptDifficultyVeryEasyFloor() {
        let result = ExerciseGenerator.adaptDifficulty(current: .veryEasy, recentAccuracy: 0.0)
        XCTAssertEqual(result, .veryEasy)
    }
}
