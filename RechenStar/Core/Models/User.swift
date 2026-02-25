import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var avatarCharacter: String = "star"
    var avatarColor: String = "#4A90E2"
    var createdAt: Date = Date()
    var lastActiveAt: Date = Date()

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalExercises: Int = 0
    var totalStars: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \DailyProgress.user)
    var progress: [DailyProgress] = []

    @Relationship(deleteRule: .cascade, inverse: \Achievement.user)
    var achievements: [Achievement] = []

    @Relationship(deleteRule: .cascade, inverse: \UserPreferences.user)
    var preferences: UserPreferences?

    @Relationship(deleteRule: .cascade, inverse: \AdjustmentLog.user)
    var adjustmentLogs: [AdjustmentLog] = []

    init(name: String = "", avatarCharacter: String = "star") {
        self.name = name
        self.avatarCharacter = avatarCharacter
    }
}
