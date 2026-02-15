import XCTest
@testable import RechenStar

final class ExerciseGeneratorTests: XCTestCase {

    func testGenerateReturnsValidExercise() {
        let exercise = ExerciseGenerator.generate(difficulty: .easy, category: .addition_10)
        XCTAssertGreaterThanOrEqual(exercise.correctAnswer, 0)
        XCTAssertGreaterThanOrEqual(exercise.firstNumber, 1)
        XCTAssertGreaterThanOrEqual(exercise.secondNumber, 1)
    }

    func testAddition10NeverExceedsTen() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .hard,
                category: .addition_10
            )
            XCTAssertLessThanOrEqual(
                exercise.firstNumber + exercise.secondNumber, 10,
                "Addition \(exercise.firstNumber) + \(exercise.secondNumber) exceeds 10"
            )
        }
    }

    func testAddition100NeverExceeds100() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .hard,
                category: .addition_100
            )
            XCTAssertLessThanOrEqual(
                exercise.firstNumber + exercise.secondNumber, 100,
                "Addition \(exercise.firstNumber) + \(exercise.secondNumber) exceeds 100"
            )
            XCTAssertGreaterThanOrEqual(exercise.firstNumber, 1)
            XCTAssertGreaterThanOrEqual(exercise.secondNumber, 1)
        }
    }

    func testSubtraction10NeverNegative() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .hard,
                category: .subtraction_10
            )
            XCTAssertGreaterThanOrEqual(
                exercise.firstNumber - exercise.secondNumber, 0,
                "Subtraction \(exercise.firstNumber) - \(exercise.secondNumber) is negative"
            )
        }
    }

    func testSubtraction100AllowsNegative() {
        var hasNegative = false
        for _ in 0..<200 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .hard,
                category: .subtraction_100
            )
            if exercise.firstNumber - exercise.secondNumber < 0 {
                hasNegative = true
                break
            }
        }
        XCTAssertTrue(hasNegative, "Subtraction 100 should allow negative results")
    }

    func testMultiplication10FactorsInRange() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .hard,
                category: .multiplication_10
            )
            XCTAssertGreaterThanOrEqual(exercise.firstNumber, 1)
            XCTAssertLessThanOrEqual(exercise.firstNumber, 10)
            XCTAssertGreaterThanOrEqual(exercise.secondNumber, 1)
            XCTAssertLessThanOrEqual(exercise.secondNumber, 10)
            XCTAssertEqual(exercise.type, .multiplication)
        }
    }

    func testMultiplication100ProductNotExceeds100() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .hard,
                category: .multiplication_100
            )
            XCTAssertLessThanOrEqual(
                exercise.firstNumber * exercise.secondNumber, 100,
                "Multiplication \(exercise.firstNumber) × \(exercise.secondNumber) exceeds 100"
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
                let exercise = ExerciseGenerator.generate(difficulty: difficulty, category: .addition_10)
                XCTAssertGreaterThanOrEqual(exercise.firstNumber, lower)
                XCTAssertLessThanOrEqual(exercise.firstNumber, upper)
                XCTAssertGreaterThanOrEqual(exercise.secondNumber, lower)
                XCTAssertLessThanOrEqual(exercise.secondNumber, upper)
            }
        }
    }

    func testGenerateSessionCorrectCount() {
        let exercises = ExerciseGenerator.generateSession(count: 10, difficulty: .easy, categories: [.addition_10, .subtraction_10])
        XCTAssertEqual(exercises.count, 10)
    }

    func testGenerateSessionNoDuplicates() {
        let exercises = ExerciseGenerator.generateSession(count: 10, difficulty: .hard, categories: [.addition_10, .subtraction_10])
        let signatures = exercises.map(\.signature)
        let unique = Set(signatures)
        XCTAssertEqual(unique.count, signatures.count, "Duplicate signatures found")
    }

    func testExcludingSignaturesRespected() {
        let excluded: Set<String> = ["addition_10_1_2", "addition_10_3_4"]
        for _ in 0..<50 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .easy,
                category: .addition_10,
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

    func testGenerateSessionWithMultipleCategories() {
        let categories: [ExerciseCategory] = [.addition_10, .subtraction_10, .multiplication_10]
        let exercises = ExerciseGenerator.generateSession(count: 30, difficulty: .easy, categories: categories)
        XCTAssertEqual(exercises.count, 30)

        let categorySet = Set(exercises.map(\.category))
        // With 30 exercises and 3 categories, statistically all should appear
        XCTAssertTrue(categorySet.count >= 2, "Expected at least 2 categories in session")
    }
}
