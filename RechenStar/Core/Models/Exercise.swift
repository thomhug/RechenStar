import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    let type: OperationType
    let firstNumber: Int
    let secondNumber: Int
    let difficulty: Difficulty
    let createdAt: Date

    var correctAnswer: Int {
        switch type {
        case .addition: firstNumber + secondNumber
        case .subtraction: firstNumber - secondNumber
        }
    }

    var displayText: String {
        "\(firstNumber) \(type.symbol) \(secondNumber) = ?"
    }

    var signature: String {
        "\(type.rawValue)_\(firstNumber)_\(secondNumber)"
    }

    init(
        type: OperationType,
        firstNumber: Int,
        secondNumber: Int,
        difficulty: Difficulty = .easy
    ) {
        self.id = UUID()
        self.type = type
        self.firstNumber = firstNumber
        self.secondNumber = secondNumber
        self.difficulty = difficulty
        self.createdAt = Date()
    }
}

enum OperationType: String, Codable, CaseIterable {
    case addition = "plus"
    case subtraction = "minus"

    var symbol: String {
        switch self {
        case .addition: "+"
        case .subtraction: "-"
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
