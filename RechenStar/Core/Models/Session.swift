import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID = UUID()
    var startTime: Date = Date()
    var endTime: Date?
    var isCompleted: Bool = false
    var sessionGoal: Int = 10
    var correctCount: Int = 0
    var totalCount: Int = 0
    var starsEarned: Int = 0

    @Relationship(inverse: \DailyProgress.sessions)
    var dailyProgress: DailyProgress?

    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var accuracy: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }

    init() {}
}
