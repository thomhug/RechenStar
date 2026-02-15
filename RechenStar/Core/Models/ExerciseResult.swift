import Foundation

struct ExerciseResult: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let userAnswer: Int
    let isCorrect: Bool
    let attempts: Int
    let timeSpent: TimeInterval

    var stars: Int {
        guard isCorrect else { return 0 }
        switch attempts {
        case 1: return 3
        case 2: return 2
        default: return 1
        }
    }
}
