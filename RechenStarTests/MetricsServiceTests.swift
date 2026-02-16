import XCTest
@testable import RechenStar

final class MetricsServiceTests: XCTestCase {

    func testEmptyRecordsReturnsNil() {
        let result = MetricsService.computeMetrics(from: [])
        XCTAssertNil(result)
    }

    func testCategoryAccuracyCorrect() {
        let records: [MetricsService.RecordData] = [
            .init(category: .addition_10, exerciseSignature: "addition_10_3_4", firstNumber: 3, secondNumber: 4, isCorrect: true),
            .init(category: .addition_10, exerciseSignature: "addition_10_5_2", firstNumber: 5, secondNumber: 2, isCorrect: true),
            .init(category: .addition_10, exerciseSignature: "addition_10_1_6", firstNumber: 1, secondNumber: 6, isCorrect: false),
            .init(category: .subtraction_10, exerciseSignature: "subtraction_10_8_3", firstNumber: 8, secondNumber: 3, isCorrect: true),
            .init(category: .subtraction_10, exerciseSignature: "subtraction_10_7_2", firstNumber: 7, secondNumber: 2, isCorrect: false),
        ]

        let metrics = MetricsService.computeMetrics(from: records)
        XCTAssertNotNil(metrics)

        // addition_10: 2/3 correct = 0.667
        XCTAssertEqual(metrics!.categoryAccuracy[.addition_10]!, 2.0 / 3.0, accuracy: 0.001)
        // subtraction_10: 1/2 correct = 0.5
        XCTAssertEqual(metrics!.categoryAccuracy[.subtraction_10]!, 0.5, accuracy: 0.001)
    }

    func testWeakExercisesDetected() {
        // Same signature, mostly wrong -> should be weak
        let records: [MetricsService.RecordData] = [
            .init(category: .addition_10, exerciseSignature: "addition_10_3_7", firstNumber: 3, secondNumber: 7, isCorrect: false),
            .init(category: .addition_10, exerciseSignature: "addition_10_3_7", firstNumber: 3, secondNumber: 7, isCorrect: false),
            .init(category: .addition_10, exerciseSignature: "addition_10_3_7", firstNumber: 3, secondNumber: 7, isCorrect: true),
        ]

        let metrics = MetricsService.computeMetrics(from: records)
        XCTAssertNotNil(metrics)

        // 1/3 correct = 0.333 < 0.6, total >= 2 -> weak
        let weak = metrics!.weakExercises[.addition_10] ?? []
        XCTAssertEqual(weak.count, 1)
        XCTAssertEqual(weak.first?.first, 3)
        XCTAssertEqual(weak.first?.second, 7)
    }

    func testSingleWrongAttemptIsWeak() {
        // 1 attempt, wrong -> weak (so revenge triggers next time)
        let records: [MetricsService.RecordData] = [
            .init(category: .subtraction_10, exerciseSignature: "subtraction_10_8_5", firstNumber: 8, secondNumber: 5, isCorrect: false),
        ]

        let metrics = MetricsService.computeMetrics(from: records)
        XCTAssertNotNil(metrics)

        let weak = metrics!.weakExercises[.subtraction_10] ?? []
        XCTAssertEqual(weak.count, 1)
        XCTAssertEqual(weak.first?.first, 8)
        XCTAssertEqual(weak.first?.second, 5)
    }

    func testStrongExercisesNotInWeakExercises() {
        // Same signature, mostly correct -> NOT weak
        let records: [MetricsService.RecordData] = [
            .init(category: .addition_10, exerciseSignature: "addition_10_2_3", firstNumber: 2, secondNumber: 3, isCorrect: true),
            .init(category: .addition_10, exerciseSignature: "addition_10_2_3", firstNumber: 2, secondNumber: 3, isCorrect: true),
            .init(category: .addition_10, exerciseSignature: "addition_10_2_3", firstNumber: 2, secondNumber: 3, isCorrect: false),
        ]

        let metrics = MetricsService.computeMetrics(from: records)
        XCTAssertNotNil(metrics)

        // 2/3 correct = 0.667 >= 0.6 -> NOT weak
        let weak = metrics!.weakExercises[.addition_10] ?? []
        XCTAssertTrue(weak.isEmpty)
    }
}
