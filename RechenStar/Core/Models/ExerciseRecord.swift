import Foundation
import SwiftData

@Model
final class ExerciseRecord {
    var id: UUID = UUID()
    var exerciseSignature: String = ""  // e.g. "addition_10_3_4"
    var operationType: String = ""      // "plus", "minus", or "mal"
    var category: String = ""           // e.g. "addition_10"
    var firstNumber: Int = 0
    var secondNumber: Int = 0
    var isCorrect: Bool = false
    var timeSpent: TimeInterval = 0
    var attempts: Int = 1
    var wasSkipped: Bool = false
    var difficulty: Int = 2
    var date: Date = Date()

    var session: Session?

    var displayText: String {
        let symbol: String
        switch operationType {
        case "plus": symbol = "+"
        case "minus": symbol = "-"
        case "mal": symbol = "×"
        default: symbol = "?"
        }
        return "\(firstNumber) \(symbol) \(secondNumber)"
    }

    init(exercise: Exercise, result: ExerciseResult) {
        self.exerciseSignature = exercise.signature
        self.operationType = exercise.type.rawValue
        self.category = exercise.category.rawValue
        self.firstNumber = exercise.firstNumber
        self.secondNumber = exercise.secondNumber
        self.isCorrect = result.isCorrect
        self.timeSpent = result.timeSpent
        self.attempts = result.attempts
        self.wasSkipped = result.wasSkipped
        self.difficulty = exercise.difficulty.rawValue
        self.date = Date()
    }
}
