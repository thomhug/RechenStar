import Foundation

struct ExerciseMetrics {
    let categoryAccuracy: [ExerciseCategory: Double]
    let weakExercises: [ExerciseCategory: [(first: Int, second: Int)]]
}

struct ExerciseGenerator {

    static func generate(
        difficulty: Difficulty = .easy,
        category: ExerciseCategory,
        excluding signatures: Set<String> = [],
        metrics: ExerciseMetrics? = nil
    ) -> Exercise {
        // 30% chance to use a weak exercise if available
        if let metrics = metrics,
           let weakPairs = metrics.weakExercises[category],
           !weakPairs.isEmpty,
           Double.random(in: 0..<1) < 0.3 {
            let pair = weakPairs.randomElement()!
            let exercise = Exercise(
                type: category.operationType,
                category: category,
                firstNumber: pair.first,
                secondNumber: pair.second,
                difficulty: difficulty
            )
            if !signatures.contains(exercise.signature) {
                return exercise
            }
        }

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
        categories: [ExerciseCategory] = [.addition_10, .subtraction_10],
        metrics: ExerciseMetrics? = nil
    ) -> [Exercise] {
        var exercises: [Exercise] = []
        var usedSignatures: Set<String> = []

        for _ in 0..<count {
            let category = weightedRandomCategory(from: categories, metrics: metrics)
            let exercise = generate(difficulty: difficulty, category: category, excluding: usedSignatures, metrics: metrics)
            exercises.append(exercise)
            usedSignatures.insert(exercise.signature)
        }

        return exercises
    }

    static func adaptDifficulty(
        current: Difficulty,
        recentAccuracy: Double,
        averageTime: TimeInterval = .infinity
    ) -> Difficulty {
        if recentAccuracy >= 0.9 && averageTime < 3.0 {
            // Fast and accurate: jump 2 levels
            return nextHigher(nextHigher(current))
        } else if recentAccuracy >= 0.9 {
            return nextHigher(current)
        } else if recentAccuracy < 0.5 {
            return nextLower(current)
        }
        return current
    }

    /// Determine starting difficulty from historical metrics
    static func startingDifficulty(from metrics: ExerciseMetrics?) -> Difficulty {
        guard let metrics = metrics, !metrics.categoryAccuracy.isEmpty else {
            return .veryEasy
        }
        let avgAccuracy = metrics.categoryAccuracy.values.reduce(0, +) / Double(metrics.categoryAccuracy.count)
        if avgAccuracy >= 0.9 { return .hard }
        if avgAccuracy >= 0.7 { return .medium }
        if avgAccuracy >= 0.5 { return .easy }
        return .veryEasy
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
            let range100 = difficulty.range100
            let first = Int.random(in: range100)
            let maxSecond = min(range100.upperBound, 100 - first)
            let second = Int.random(in: 1...max(1, maxSecond))
            return Exercise(type: .addition, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty)

        case .subtraction_10:
            let range = difficulty.range
            let first = Int.random(in: range)
            let second = Int.random(in: range.lowerBound...first)
            return Exercise(type: .subtraction, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty)

        case .subtraction_100:
            let range100 = difficulty.range100
            let first = Int.random(in: range100)
            let second = Int.random(in: range100)
            return Exercise(type: .subtraction, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty)

        case .multiplication_10:
            let range = difficulty.range
            let first = Int.random(in: range)
            let second = Int.random(in: range)
            return Exercise(type: .multiplication, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty)

        case .multiplication_100:
            let maxProduct = difficulty.maxProduct
            let minFactor = difficulty.range.lowerBound
            let first = Int.random(in: minFactor...20)
            let maxSecond = min(20, maxProduct / max(first, 1))
            let second = Int.random(in: minFactor...max(minFactor, maxSecond))
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

    static func weightedRandomCategory(
        from categories: [ExerciseCategory],
        metrics: ExerciseMetrics?
    ) -> ExerciseCategory {
        guard let metrics = metrics, !categories.isEmpty else {
            return categories.randomElement()!
        }

        let weights = categories.map { category -> Double in
            if let accuracy = metrics.categoryAccuracy[category] {
                return 1.0 + (1.0 - accuracy)
            }
            return 1.0
        }

        let totalWeight = weights.reduce(0, +)
        var random = Double.random(in: 0..<totalWeight)

        for (index, weight) in weights.enumerated() {
            random -= weight
            if random <= 0 {
                return categories[index]
            }
        }

        return categories.last!
    }
}
