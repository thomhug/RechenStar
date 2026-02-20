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
        metrics: ExerciseMetrics? = nil,
        allowGapFill: Bool = false
    ) -> Exercise {
        let format = randomFormat(for: category, allowGapFill: allowGapFill)

        // Chance to use a weak exercise if available
        if let metrics = metrics,
           let weakPairs = metrics.weakExercises[category],
           !weakPairs.isEmpty,
           Double.random(in: 0..<1) < ExerciseConstants.weakExerciseChance {
            let pair = weakPairs.randomElement()!
            let exercise = Exercise(
                type: category.operationType,
                category: category,
                firstNumber: pair.first,
                secondNumber: pair.second,
                difficulty: difficulty,
                format: format,
                isRetry: true
            )
            if !signatures.contains(exercise.signature) {
                return exercise
            }
        }

        for _ in 0..<50 {
            let exercise = randomExercise(category: category, difficulty: difficulty, format: format)
            if !signatures.contains(exercise.signature) {
                return exercise
            }
        }

        return randomExercise(category: category, difficulty: difficulty, format: format)
    }

    static func generateSession(
        count: Int = 10,
        difficulty: Difficulty = .easy,
        categories: [ExerciseCategory] = [.addition_10, .subtraction_10],
        metrics: ExerciseMetrics? = nil,
        allowGapFill: Bool = false
    ) -> [Exercise] {
        var exercises: [Exercise] = []
        var usedSignatures: Set<String> = []

        for _ in 0..<count {
            let category = weightedRandomCategory(from: categories, metrics: metrics)
            let exercise = generate(difficulty: difficulty, category: category, excluding: usedSignatures, metrics: metrics, allowGapFill: allowGapFill)
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
        // Slow → down (child is struggling, even if answers are correct)
        if averageTime.isFinite && averageTime > ExerciseConstants.slowTimeThreshold {
            return nextLower(current)
        }
        // Perfect AND fast → up (automated knowledge)
        if recentAccuracy >= 1.0 && averageTime < ExerciseConstants.fastTimeThreshold {
            return nextHigher(current)
        }
        // All wrong → down
        if recentAccuracy < 0.01 {
            return nextLower(current)
        }
        // Otherwise stay (partial success, or correct but slow)
        return current
    }

    /// Determine starting difficulty from historical metrics
    static func startingDifficulty(from metrics: ExerciseMetrics?) -> Difficulty {
        guard let metrics = metrics, !metrics.categoryAccuracy.isEmpty else {
            return .veryEasy
        }
        let avgAccuracy = metrics.categoryAccuracy.values.reduce(0, +) / Double(metrics.categoryAccuracy.count)
        if avgAccuracy >= ExerciseConstants.startHardThreshold { return .hard }
        if avgAccuracy >= ExerciseConstants.startMediumThreshold { return .medium }
        if avgAccuracy >= ExerciseConstants.startEasyThreshold { return .easy }
        return .veryEasy
    }

    // MARK: - Private

    private static func randomExercise(
        category: ExerciseCategory,
        difficulty: Difficulty,
        format: ExerciseFormat = .standard
    ) -> Exercise {
        switch category {
        case .addition_10:
            let range = difficulty.range
            let maxFirst = min(range.upperBound, 10 - range.lowerBound)
            let first = Int.random(in: range.lowerBound...maxFirst)
            let maxSecond = min(range.upperBound, 10 - first)
            let second = Int.random(in: range.lowerBound...maxSecond)
            return Exercise(type: .addition, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty, format: format)

        case .addition_100:
            let range100 = difficulty.range100
            let maxFirst = 100 - range100.lowerBound // leave room for second ≥ lowerBound
            let first = Int.random(in: range100.lowerBound...min(range100.upperBound, maxFirst))
            let maxSecond = min(range100.upperBound, 100 - first)
            let second = Int.random(in: range100.lowerBound...max(range100.lowerBound, maxSecond))
            return Exercise(type: .addition, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty, format: format)

        case .subtraction_10:
            let range = difficulty.range
            let first = Int.random(in: range)
            let second = Int.random(in: range.lowerBound...first)
            return Exercise(type: .subtraction, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty, format: format)

        case .subtraction_100:
            let range100 = difficulty.range100
            let first = Int.random(in: range100)
            let second = Int.random(in: range100)
            return Exercise(type: .subtraction, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty, format: format)

        case .multiplication_10:
            let range = difficulty.range
            let minFactor = max(range.lowerBound, ExerciseConstants.minimumMultiplicationFactor)
            let first = Int.random(in: minFactor...range.upperBound)
            let second = Int.random(in: minFactor...range.upperBound)
            return Exercise(type: .multiplication, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty, format: format)

        case .multiplication_100:
            let maxProduct = difficulty.maxProduct
            let minFactor = max(difficulty.range.lowerBound, ExerciseConstants.minimumMultiplicationFactor)
            let excludedFactors: Set<Int> = difficulty == .hard ? ExerciseConstants.excludedHardMultiplicationFactors : []
            var first: Int
            var second: Int
            repeat {
                first = Int.random(in: minFactor...20)
                let maxSecond = min(20, maxProduct / max(first, 1))
                second = Int.random(in: minFactor...max(minFactor, maxSecond))
            } while excludedFactors.contains(first) || excludedFactors.contains(second)
            return Exercise(type: .multiplication, category: category, firstNumber: first, secondNumber: second, difficulty: difficulty, format: format)
        }
    }

    private static func randomFormat(for category: ExerciseCategory, allowGapFill: Bool) -> ExerciseFormat {
        guard allowGapFill else { return .standard }
        // Only addition/subtraction bis 10
        guard category == .addition_10 || category == .subtraction_10 else { return .standard }
        guard Double.random(in: 0..<1) < ExerciseConstants.gapFillChance else { return .standard }
        return Bool.random() ? .firstGap : .secondGap
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
