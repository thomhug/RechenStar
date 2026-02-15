import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    let type: OperationType
    let category: ExerciseCategory
    let firstNumber: Int
    let secondNumber: Int
    let difficulty: Difficulty
    let createdAt: Date

    var correctAnswer: Int {
        switch type {
        case .addition: firstNumber + secondNumber
        case .subtraction: firstNumber - secondNumber
        case .multiplication: firstNumber * secondNumber
        }
    }

    var displayText: String {
        "\(firstNumber) \(type.symbol) \(secondNumber) = ?"
    }

    var signature: String {
        "\(category.rawValue)_\(firstNumber)_\(secondNumber)"
    }

    init(
        type: OperationType,
        category: ExerciseCategory,
        firstNumber: Int,
        secondNumber: Int,
        difficulty: Difficulty = .easy
    ) {
        self.id = UUID()
        self.type = type
        self.category = category
        self.firstNumber = firstNumber
        self.secondNumber = secondNumber
        self.difficulty = difficulty
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
        case .medium: 1...7
        case .hard: 1...10
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
}
