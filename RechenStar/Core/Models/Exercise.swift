import Foundation

enum ExerciseFormat: String, Codable {
    case standard    // "3 + 4 = ?"  → Antwort: Ergebnis
    case firstGap    // "? + 4 = 7"  → Antwort: erster Operand
    case secondGap   // "3 + ? = 7"  → Antwort: zweiter Operand
}

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    let type: OperationType
    let category: ExerciseCategory
    let firstNumber: Int
    let secondNumber: Int
    let difficulty: Difficulty
    let format: ExerciseFormat
    let isRetry: Bool
    let createdAt: Date

    var correctAnswer: Int {
        switch format {
        case .standard:
            switch type {
            case .addition: firstNumber + secondNumber
            case .subtraction: firstNumber - secondNumber
            case .multiplication: firstNumber * secondNumber
            }
        case .firstGap:
            firstNumber
        case .secondGap:
            secondNumber
        }
    }

    /// The full result of the operation (used for display in gap-fill mode)
    var operationResult: Int {
        switch type {
        case .addition: firstNumber + secondNumber
        case .subtraction: firstNumber - secondNumber
        case .multiplication: firstNumber * secondNumber
        }
    }

    var displayNumbers: (left: String, right: String, result: String) {
        switch format {
        case .standard:
            ("\(firstNumber)", "\(secondNumber)", "?")
        case .firstGap:
            ("?", "\(secondNumber)", "\(operationResult)")
        case .secondGap:
            ("\(firstNumber)", "?", "\(operationResult)")
        }
    }

    var displayText: String {
        let d = displayNumbers
        return "\(d.left) \(type.symbol) \(d.right) = \(d.result)"
    }

    var signature: String {
        "\(category.rawValue)_\(firstNumber)_\(secondNumber)_\(format.rawValue)"
    }

    init(
        type: OperationType,
        category: ExerciseCategory,
        firstNumber: Int,
        secondNumber: Int,
        difficulty: Difficulty = .easy,
        format: ExerciseFormat = .standard,
        isRetry: Bool = false
    ) {
        self.id = UUID()
        self.type = type
        self.category = category
        self.firstNumber = firstNumber
        self.secondNumber = secondNumber
        self.difficulty = difficulty
        self.format = format
        self.isRetry = isRetry
        self.createdAt = Date()
    }
}

enum OperationType: String, Codable, CaseIterable {
    case addition = "plus"
    case subtraction = "minus"
    case multiplication = "mal"

    var symbol: String {
        switch self {
        case .addition: "+"
        case .subtraction: "-"
        case .multiplication: "×"
        }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case addition_10
    case addition_100
    case subtraction_10
    case subtraction_100
    case multiplication_10
    case multiplication_100

    var label: String {
        switch self {
        case .addition_10: "Addition bis 10"
        case .addition_100: "Addition bis 100"
        case .subtraction_10: "Subtraktion bis 10"
        case .subtraction_100: "Subtraktion bis 100"
        case .multiplication_10: "Kleines 1×1"
        case .multiplication_100: "Grosses 1×1"
        }
    }

    var operationType: OperationType {
        switch self {
        case .addition_10, .addition_100: .addition
        case .subtraction_10, .subtraction_100: .subtraction
        case .multiplication_10, .multiplication_100: .multiplication
        }
    }

    var icon: String {
        switch self {
        case .addition_10, .addition_100: "plus.circle.fill"
        case .subtraction_10, .subtraction_100: "minus.circle.fill"
        case .multiplication_10, .multiplication_100: "multiply.circle.fill"
        }
    }

    var groupLabel: String {
        switch self {
        case .addition_10, .addition_100: "Addition"
        case .subtraction_10, .subtraction_100: "Subtraktion"
        case .multiplication_10, .multiplication_100: "Multiplikation"
        }
    }
}

enum Difficulty: Int, Codable, CaseIterable {
    case veryEasy = 1
    case easy = 2
    case medium = 3
    case hard = 4

    var range: ClosedRange<Int> {
        switch self {
        case .veryEasy: 1...3
        case .easy: 1...5
        case .medium: 2...7
        case .hard: 2...9
        }
    }

    var range100: ClosedRange<Int> {
        switch self {
        case .veryEasy: 1...20
        case .easy: 1...40
        case .medium: 2...70
        case .hard: 2...99
        }
    }

    var maxProduct: Int {
        switch self {
        case .veryEasy: 50
        case .easy: 100
        case .medium: 200
        case .hard: 400
        }
    }

    var label: String {
        switch self {
        case .veryEasy: "Sehr leicht"
        case .easy: "Leicht"
        case .medium: "Mittel"
        case .hard: "Schwer"
        }
    }

    var skillTitle: String {
        switch self {
        case .veryEasy: "Entdecker"
        case .easy: "Kenner"
        case .medium: "Könner"
        case .hard: "Meister"
        }
    }

    var skillImageName: String {
        switch self {
        case .veryEasy: "skill_entdecker"
        case .easy: "skill_kenner"
        case .medium: "skill_koenner"
        case .hard: "skill_meister"
        }
    }
}
