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
            XCTAssertGreaterThanOrEqual(exercise.firstNumber, 2)
            XCTAssertGreaterThanOrEqual(exercise.secondNumber, 1) // second can be capped by sum constraint
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
            XCTAssertGreaterThanOrEqual(exercise.firstNumber, 2)
            XCTAssertLessThanOrEqual(exercise.firstNumber, 9)
            XCTAssertGreaterThanOrEqual(exercise.secondNumber, 2)
            XCTAssertLessThanOrEqual(exercise.secondNumber, 9)
            XCTAssertEqual(exercise.type, .multiplication)
        }
    }

    func testMultiplication100ProductNotExceeds400() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .hard,
                category: .multiplication_100
            )
            XCTAssertLessThanOrEqual(
                exercise.firstNumber * exercise.secondNumber, 400,
                "Multiplication \(exercise.firstNumber) × \(exercise.secondNumber) exceeds 400"
            )
            XCTAssertLessThanOrEqual(exercise.firstNumber, 20)
            XCTAssertLessThanOrEqual(exercise.secondNumber, 20)
        }
    }

    func testDifficultyRanges() {
        let cases: [(Difficulty, Int, Int)] = [
            (.veryEasy, 1, 3),
            (.easy, 1, 5),
            (.medium, 2, 7),
            (.hard, 2, 9),
        ]

        for (difficulty, lower, upper) in cases {
            for _ in 0..<50 {
                let exercise = ExerciseGenerator.generate(difficulty: difficulty, category: .addition_10)
                XCTAssertGreaterThanOrEqual(exercise.firstNumber, lower,
                    "\(difficulty) firstNumber \(exercise.firstNumber) below min \(lower)")
                XCTAssertLessThanOrEqual(exercise.firstNumber, upper)
                XCTAssertGreaterThanOrEqual(exercise.secondNumber, lower,
                    "\(difficulty) secondNumber \(exercise.secondNumber) below min \(lower)")
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

    func testAdaptDifficultyFastAndAccurateJumps2Levels() {
        let result = ExerciseGenerator.adaptDifficulty(current: .easy, recentAccuracy: 1.0, averageTime: 2.0)
        XCTAssertEqual(result, .hard)
    }

    func testAdaptDifficultyFastFromVeryEasyToMedium() {
        let result = ExerciseGenerator.adaptDifficulty(current: .veryEasy, recentAccuracy: 1.0, averageTime: 1.5)
        XCTAssertEqual(result, .medium)
    }

    func testAdaptDifficultyHardCeiling() {
        let result = ExerciseGenerator.adaptDifficulty(current: .hard, recentAccuracy: 1.0)
        XCTAssertEqual(result, .hard)
    }

    func testAdaptDifficultyVeryEasyFloor() {
        let result = ExerciseGenerator.adaptDifficulty(current: .veryEasy, recentAccuracy: 0.0)
        XCTAssertEqual(result, .veryEasy)
    }

    func testAddition100RespectsEasyDifficulty() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(difficulty: .easy, category: .addition_100)
            XCTAssertLessThanOrEqual(exercise.firstNumber, 40,
                "Easy addition_100 first number \(exercise.firstNumber) exceeds 40")
            XCTAssertLessThanOrEqual(exercise.firstNumber + exercise.secondNumber, 100)
        }
    }

    func testSubtraction100RespectsEasyDifficulty() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(difficulty: .easy, category: .subtraction_100)
            XCTAssertLessThanOrEqual(exercise.firstNumber, 40,
                "Easy subtraction_100 first number \(exercise.firstNumber) exceeds 40")
            XCTAssertLessThanOrEqual(exercise.secondNumber, 40)
        }
    }

    func testMultiplication100RespectsEasyDifficulty() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(difficulty: .easy, category: .multiplication_100)
            XCTAssertLessThanOrEqual(exercise.firstNumber * exercise.secondNumber, 100,
                "Easy multiplication_100 product \(exercise.firstNumber * exercise.secondNumber) exceeds 100")
        }
    }

    func testMultiplication100HardAllowsFullRange() {
        var hasLargeProduct = false
        for _ in 0..<200 {
            let exercise = ExerciseGenerator.generate(difficulty: .hard, category: .multiplication_100)
            XCTAssertLessThanOrEqual(exercise.firstNumber * exercise.secondNumber, 400)
            if exercise.firstNumber * exercise.secondNumber > 200 {
                hasLargeProduct = true
            }
        }
        XCTAssertTrue(hasLargeProduct, "Hard multiplication_100 should produce products > 200")
    }

    func testGenerateSessionWithMultipleCategories() {
        let categories: [ExerciseCategory] = [.addition_10, .subtraction_10, .multiplication_10]
        let exercises = ExerciseGenerator.generateSession(count: 30, difficulty: .easy, categories: categories)
        XCTAssertEqual(exercises.count, 30)

        let categorySet = Set(exercises.map(\.category))
        // With 30 exercises and 3 categories, statistically all should appear
        XCTAssertTrue(categorySet.count >= 2, "Expected at least 2 categories in session")
    }

    // MARK: - Weighted Category Selection

    func testWeightedCategoryPrefersWeakCategories() {
        let metrics = ExerciseMetrics(
            categoryAccuracy: [
                .addition_10: 0.9,    // strong → weight 1.1
                .subtraction_10: 0.3  // weak → weight 1.7
            ],
            weakExercises: [:]
        )

        var counts: [ExerciseCategory: Int] = [.addition_10: 0, .subtraction_10: 0]
        let categories: [ExerciseCategory] = [.addition_10, .subtraction_10]

        for _ in 0..<1000 {
            let cat = ExerciseGenerator.weightedRandomCategory(from: categories, metrics: metrics)
            counts[cat, default: 0] += 1
        }

        // subtraction (weight 1.7) should appear more than addition (weight 1.1)
        XCTAssertGreaterThan(
            counts[.subtraction_10]!, counts[.addition_10]!,
            "Weak category should be chosen more often: sub=\(counts[.subtraction_10]!) add=\(counts[.addition_10]!)"
        )
    }

    func testWeakExercisesInjectedWhenAvailable() {
        let metrics = ExerciseMetrics(
            categoryAccuracy: [:],
            weakExercises: [.addition_10: [(first: 2, second: 3)]]
        )

        var weakCount = 0
        for _ in 0..<200 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .easy,
                category: .addition_10,
                metrics: metrics
            )
            if exercise.firstNumber == 2 && exercise.secondNumber == 3 {
                weakCount += 1
            }
        }

        // With 30% chance and only one weak pair, expect significantly more than random
        XCTAssertGreaterThan(weakCount, 10,
            "Weak exercise (2+3) should appear frequently, got \(weakCount)/200")
    }

    func testWeakExercisesMarkedAsRetry() {
        let metrics = ExerciseMetrics(
            categoryAccuracy: [:],
            weakExercises: [.addition_10: [(first: 2, second: 3)]]
        )

        var retryCount = 0
        var nonRetryCount = 0
        for _ in 0..<200 {
            let exercise = ExerciseGenerator.generate(
                difficulty: .easy,
                category: .addition_10,
                metrics: metrics
            )
            if exercise.isRetry {
                retryCount += 1
                // Retry exercises must come from the weak pool
                XCTAssertEqual(exercise.firstNumber, 2)
                XCTAssertEqual(exercise.secondNumber, 3)
            } else {
                nonRetryCount += 1
            }
        }

        XCTAssertGreaterThan(retryCount, 10,
            "Weak exercises should be marked isRetry, got \(retryCount)/200")
        XCTAssertGreaterThan(nonRetryCount, 50,
            "Non-weak exercises should NOT be marked isRetry")
    }

    func testNilMetricsBehavesLikeRandom() {
        let exercises = ExerciseGenerator.generateSession(
            count: 10,
            difficulty: .easy,
            categories: [.addition_10, .subtraction_10],
            metrics: nil
        )
        XCTAssertEqual(exercises.count, 10)
        for exercise in exercises {
            XCTAssertTrue(
                exercise.category == .addition_10 || exercise.category == .subtraction_10
            )
        }
    }

    // MARK: - Starting Difficulty

    func testStartingDifficultyFromHighAccuracy() {
        let metrics = ExerciseMetrics(
            categoryAccuracy: [.addition_10: 0.95, .subtraction_10: 0.92],
            weakExercises: [:]
        )
        XCTAssertEqual(ExerciseGenerator.startingDifficulty(from: metrics), .hard)
    }

    func testStartingDifficultyFromMediumAccuracy() {
        let metrics = ExerciseMetrics(
            categoryAccuracy: [.addition_10: 0.75, .subtraction_10: 0.8],
            weakExercises: [:]
        )
        XCTAssertEqual(ExerciseGenerator.startingDifficulty(from: metrics), .medium)
    }

    func testStartingDifficultyFromNilMetrics() {
        XCTAssertEqual(ExerciseGenerator.startingDifficulty(from: nil), .veryEasy)
    }

    func testMediumDifficultyExcludesOnes() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(difficulty: .medium, category: .multiplication_10)
            XCTAssertGreaterThanOrEqual(exercise.firstNumber, 2,
                "Medium multiplication should not have factor 1, got \(exercise.firstNumber)")
            XCTAssertGreaterThanOrEqual(exercise.secondNumber, 2,
                "Medium multiplication should not have factor 1, got \(exercise.secondNumber)")
        }
    }

    func testHardMultiplication100ExcludesOnes() {
        for _ in 0..<100 {
            let exercise = ExerciseGenerator.generate(difficulty: .hard, category: .multiplication_100)
            XCTAssertGreaterThanOrEqual(exercise.firstNumber, 2,
                "Hard grosses 1x1 should not have factor 1")
            XCTAssertGreaterThanOrEqual(exercise.secondNumber, 2,
                "Hard grosses 1x1 should not have factor 1")
        }
    }

    func testWeightedCategoryWithoutMetricsUsesUniform() {
        let categories: [ExerciseCategory] = [.addition_10, .subtraction_10]
        // Should not crash with nil metrics
        for _ in 0..<100 {
            let cat = ExerciseGenerator.weightedRandomCategory(from: categories, metrics: nil)
            XCTAssertTrue(categories.contains(cat))
        }
    }
}
