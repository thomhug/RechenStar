import Foundation

struct ExerciseResult: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let userAnswer: Int
    let isCorrect: Bool
    let attempts: Int
    let timeSpent: TimeInterval
    let wasRevealed: Bool
    let wasSkipped: Bool

    init(
        exercise: Exercise,
        userAnswer: Int,
        isCorrect: Bool,
        attempts: Int,
        timeSpent: TimeInterval,
        wasRevealed: Bool = false,
        wasSkipped: Bool = false
    ) {
        self.exercise = exercise
        self.userAnswer = userAnswer
        self.isCorrect = isCorrect
        self.attempts = attempts
        self.timeSpent = timeSpent
        self.wasRevealed = wasRevealed
        self.wasSkipped = wasSkipped
    }

    var stars: Int {
        guard isCorrect else { return 0 }
        switch attempts {
        case 1: return 3
        case 2: return 2
        default: return 1
        }
    }
}
