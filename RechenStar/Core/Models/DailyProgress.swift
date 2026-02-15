import Foundation
import SwiftData

@Model
final class DailyProgress {
    var date: Date = Date()
    var exercisesCompleted: Int = 0
    var correctAnswers: Int = 0
    var totalTime: TimeInterval = 0
    var sessionsCount: Int = 0

    var user: User?

    @Relationship(deleteRule: .cascade)
    var sessions: [Session] = []

    var accuracy: Double {
        guard exercisesCompleted > 0 else { return 0 }
        return Double(correctAnswers) / Double(exercisesCompleted)
    }

    var averageTimePerExercise: TimeInterval {
        guard exercisesCompleted > 0 else { return 0 }
        return totalTime / Double(exercisesCompleted)
    }

    init(date: Date = Date()) {
        self.date = date
    }
}
