import XCTest
@testable import RechenStar

final class MetricsServiceTests: XCTestCase {

    private let now = Date()

    private func record(
        _ category: ExerciseCategory,
        sig: String,
        first: Int,
        second: Int,
        correct: Bool,
        minutesAgo: Int = 0
    ) -> MetricsService.RecordData {
        .init(
            category: category,
            exerciseSignature: sig,
            firstNumber: first,
            secondNumber: second,
            isCorrect: correct,
            date: now.addingTimeInterval(TimeInterval(-minutesAgo * 60))
        )
    }

    func testEmptyRecordsReturnsNil() {
        let result = MetricsService.computeMetrics(from: [])
        XCTAssertNil(result)
    }

    func testCategoryAccuracyCorrect() {
        let records = [
            record(.addition_10, sig: "addition_10_3_4", first: 3, second: 4, correct: true),
            record(.addition_10, sig: "addition_10_5_2", first: 5, second: 2, correct: true),
            record(.addition_10, sig: "addition_10_1_6", first: 1, second: 6, correct: false),
            record(.subtraction_10, sig: "subtraction_10_8_3", first: 8, second: 3, correct: true),
            record(.subtraction_10, sig: "subtraction_10_7_2", first: 7, second: 2, correct: false),
        ]

        let metrics = MetricsService.computeMetrics(from: records)
        XCTAssertNotNil(metrics)
        XCTAssertEqual(metrics!.categoryAccuracy[.addition_10]!, 2.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(metrics!.categoryAccuracy[.subtraction_10]!, 0.5, accuracy: 0.001)
    }

    func testWeakExerciseLastAttemptWrong() {
        // 2 wrong, then 1 right (most recent) → NOT weak anymore (revenge already earned)
        let records = [
            record(.addition_10, sig: "addition_10_3_7", first: 3, second: 7, correct: false, minutesAgo: 30),
            record(.addition_10, sig: "addition_10_3_7", first: 3, second: 7, correct: false, minutesAgo: 20),
            record(.addition_10, sig: "addition_10_3_7", first: 3, second: 7, correct: true, minutesAgo: 10),
        ]

        let metrics = MetricsService.computeMetrics(from: records)!
        let weak = metrics.weakExercises[.addition_10] ?? []
        XCTAssertTrue(weak.isEmpty, "Exercise should NOT be weak after most recent attempt was correct")
    }

    func testWeakExerciseLastAttemptWrongStillWeak() {
        // Wrong, right, wrong (most recent wrong) → still weak
        let records = [
            record(.addition_10, sig: "addition_10_3_7", first: 3, second: 7, correct: false, minutesAgo: 30),
            record(.addition_10, sig: "addition_10_3_7", first: 3, second: 7, correct: true, minutesAgo: 20),
            record(.addition_10, sig: "addition_10_3_7", first: 3, second: 7, correct: false, minutesAgo: 10),
        ]

        let metrics = MetricsService.computeMetrics(from: records)!
        let weak = metrics.weakExercises[.addition_10] ?? []
        XCTAssertEqual(weak.count, 1, "Exercise should still be weak when most recent attempt is wrong")
    }

    func testSingleWrongAttemptIsWeak() {
        let records = [
            record(.subtraction_10, sig: "subtraction_10_8_5", first: 8, second: 5, correct: false),
        ]

        let metrics = MetricsService.computeMetrics(from: records)!
        let weak = metrics.weakExercises[.subtraction_10] ?? []
        XCTAssertEqual(weak.count, 1)
    }

    func testStrongExercisesNotInWeakExercises() {
        let records = [
            record(.addition_10, sig: "addition_10_2_3", first: 2, second: 3, correct: true, minutesAgo: 30),
            record(.addition_10, sig: "addition_10_2_3", first: 2, second: 3, correct: true, minutesAgo: 20),
            record(.addition_10, sig: "addition_10_2_3", first: 2, second: 3, correct: false, minutesAgo: 10),
        ]

        let metrics = MetricsService.computeMetrics(from: records)!
        // 2/3 correct = 0.667 >= 0.6 → NOT weak (even though last attempt wrong)
        let weak = metrics.weakExercises[.addition_10] ?? []
        XCTAssertTrue(weak.isEmpty)
    }

    func testExerciseDropsFromWeakAfterRevenge() {
        // Simulates: wrong → weak → revenge (correct) → no longer weak
        let beforeRevenge = [
            record(.addition_10, sig: "addition_10_4_5", first: 4, second: 5, correct: false, minutesAgo: 60),
        ]
        let metricsB = MetricsService.computeMetrics(from: beforeRevenge)!
        XCTAssertEqual(metricsB.weakExercises[.addition_10]?.count, 1, "Should be weak before revenge")

        // After revenge: add the correct answer
        let afterRevenge = beforeRevenge + [
            record(.addition_10, sig: "addition_10_4_5", first: 4, second: 5, correct: true, minutesAgo: 10),
        ]
        let metricsA = MetricsService.computeMetrics(from: afterRevenge)!
        let weak = metricsA.weakExercises[.addition_10] ?? []
        XCTAssertTrue(weak.isEmpty, "Should NOT be weak after successful revenge (last attempt correct)")
    }

    func testRevengeInDifferentFormatClearsWeak() {
        // Failed in standard format, then solved correctly in gap-fill format
        // Both should count as the same exercise (format-agnostic grouping)
        let records = [
            record(.addition_10, sig: "addition_10_3_2_standard", first: 3, second: 2, correct: false, minutesAgo: 60),
            record(.addition_10, sig: "addition_10_3_2_firstGap", first: 3, second: 2, correct: true, minutesAgo: 10),
        ]

        let metrics = MetricsService.computeMetrics(from: records)!
        let weak = metrics.weakExercises[.addition_10] ?? []
        XCTAssertTrue(weak.isEmpty,
            "Exercise solved in different format should clear weak status")
    }
}
