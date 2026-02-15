import Foundation

struct ExerciseGenerator {

    static func generate(
        difficulty: Difficulty = .easy,
        category: ExerciseCategory,
        excluding signatures: Set<String> = []
    ) -> Exercise {
        for _ in 0..<50 {
            let exercise = randomExercise(category: category, difficulty: difficulty)
            if !signatures.contains(exercise.signature) {
                return exercise
            }
        }

        return randomExercise(category: category, difficulty: difficulty)
    }

    static func generateSession(
        count: Int = 10,
        difficulty: Difficulty = .easy,
        categories: [ExerciseCategory] = [.addition_10, .subtraction_10]
    ) -> [Exercise] {
        var exercises: [Exercise] = []
        var usedSignatures: Set<String> = []

        for _ in 0..<count {
            let category = categories.randomElement()!
            let exercise = generate(difficulty: difficulty, category: category, excluding: usedSignatures)
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
        category: ExerciseCategory,
        difficulty: Difficulty
    ) -> Exercise {
        switch category {
        case .addition_10:
            let range = difficulty.range
            let maxFirst = min(range.upperBound, 10 - range.lowerBound)
            let first = Int.random(in: range.lowerBound...maxFirst)
            let maxSecond = min(range.upperBound, 10 - first)
            let second = Int.random(in: range.lowerBound...maxSecond)
            return Exercise(type: .addition, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty)

        case .addition_100:
            let first = Int.random(in: 1...99)
            let maxSecond = min(99, 100 - first)
            let second = Int.random(in: 1...maxSecond)
            return Exercise(type: .addition, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty)

        case .subtraction_10:
            let range = difficulty.range
            let first = Int.random(in: range)
            let second = Int.random(in: range.lowerBound...first)
            return Exercise(type: .subtraction, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty)

        case .subtraction_100:
            let first = Int.random(in: 1...99)
            let second = Int.random(in: 1...99)
            return Exercise(type: .subtraction, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty)

        case .multiplication_10:
            let range = difficulty.range
            let first = Int.random(in: range)
            let second = Int.random(in: range)
            return Exercise(type: .multiplication, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty)

        case .multiplication_100:
            let first = Int.random(in: 1...10)
            let maxSecond = 100 / first
            let second = Int.random(in: 1...maxSecond)
            return Exercise(type: .multiplication, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty)
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
