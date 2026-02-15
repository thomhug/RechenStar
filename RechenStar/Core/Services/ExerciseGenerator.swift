import Foundation

struct ExerciseGenerator {

    static func generate(
        difficulty: Difficulty = .easy,
        operationType: OperationType? = nil,
        excluding signatures: Set<String> = []
    ) -> Exercise {
        let type = operationType ?? OperationType.allCases.randomElement()!
        let range = difficulty.range

        for _ in 0..<50 {
            let exercise = randomExercise(type: type, range: range, difficulty: difficulty)
            if !signatures.contains(exercise.signature) {
                return exercise
            }
        }

        return randomExercise(type: type, range: range, difficulty: difficulty)
    }

    static func generateSession(
        count: Int = 10,
        difficulty: Difficulty = .easy
    ) -> [Exercise] {
        var exercises: [Exercise] = []
        var usedSignatures: Set<String> = []

        for _ in 0..<count {
            let exercise = generate(difficulty: difficulty, excluding: usedSignatures)
            exercises.append(exercise)
            usedSignatures.insert(exercise.signature)
        }

        return exercises
    }

    static func adaptDifficulty(
        current: Difficulty,
        recentAccuracy: Double
    ) -> Difficulty {
        if recentAccuracy >= 0.9 {
            return nextHigher(current)
        } else if recentAccuracy < 0.5 {
            return nextLower(current)
        }
        return current
    }

    // MARK: - Private

    private static func randomExercise(
        type: OperationType,
        range: ClosedRange<Int>,
        difficulty: Difficulty
    ) -> Exercise {
        switch type {
        case .addition:
            let maxFirst = min(range.upperBound, 10 - range.lowerBound)
            let first = Int.random(in: range.lowerBound...maxFirst)
            let maxSecond = min(range.upperBound, 10 - first)
            let second = Int.random(in: range.lowerBound...maxSecond)
            return Exercise(type: .addition, firstNumber: first, secondNumber: second, difficulty: difficulty)

        case .subtraction:
            let first = Int.random(in: range)
            let second = Int.random(in: range.lowerBound...first)
            return Exercise(type: .subtraction, firstNumber: first, secondNumber: second, difficulty: difficulty)
        }
    }

    private static func nextHigher(_ difficulty: Difficulty) -> Difficulty {
        switch difficulty {
        case .veryEasy: return .easy
        case .easy: return .medium
        case .medium: return .hard
        case .hard: return .hard
        }
    }

    private static func nextLower(_ difficulty: Difficulty) -> Difficulty {
        switch difficulty {
        case .veryEasy: return .veryEasy
        case .easy: return .veryEasy
        case .medium: return .easy
        case .hard: return .medium
        }
    }
}
