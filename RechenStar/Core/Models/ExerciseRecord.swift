import Foundation
import SwiftData

@Model
final class ExerciseRecord {
    var id: UUID = UUID()
    var exerciseSignature: String = ""  // e.g. "plus_3_4" or "minus_7_2"
    var operationType: String = ""      // "plus" or "minus"
    var firstNumber: Int = 0
    var secondNumber: Int = 0
    var isCorrect: Bool = false
    var timeSpent: TimeInterval = 0
    var attempts: Int = 1
    var date: Date = Date()

    var session: Session?

    var displayText: String {
        let symbol = operationType == "plus" ? "+" : "-"
        return "\(firstNumber) \(symbol) \(secondNumber)"
    }

    init(exercise: Exercise, result: ExerciseResult) {
        self.exerciseSignature = exercise.signature
        self.operationType = exercise.type.rawValue
        self.firstNumber = exercise.firstNumber
        self.secondNumber = exercise.secondNumber
        self.isCorrect = result.isCorrect
        self.timeSpent = result.timeSpent
        self.attempts = result.attempts
        self.date = Date()
    }
}
