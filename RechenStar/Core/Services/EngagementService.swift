import Foundation
import SwiftData

struct EngagementResult {
    let newlyUnlockedAchievements: [Achievement]
    let currentStreak: Int
    let isNewStreak: Bool
}

struct EngagementService {

    // MARK: - Main Entry Point

    static func processSession(
        results: [ExerciseResult],
        session: Session,
        user: User,
        context: ModelContext
    ) -> EngagementResult {
        updateDailyProgress(session: session, results: results, user: user, context: context)
        let streakResult = updateStreak(user: user)
        let unlocked = checkAchievements(user: user, session: session, results: results, context: context)

        user.lastActiveAt = Date()
        try? context.save()

        return EngagementResult(
            newlyUnlockedAchievements: unlocked,
            currentStreak: streakResult.streak,
            isNewStreak: streakResult.isNew
        )
    }

    // MARK: - Daily Progress

    static func updateDailyProgress(
        session: Session,
        results: [ExerciseResult],
        user: User,
        context: ModelContext
    ) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        let daily = user.progress.first { calendar.isDate($0.date, inSameDayAs: todayStart) }
            ?? createDailyProgress(date: todayStart, user: user, context: context)

        daily.exercisesCompleted += results.count
        daily.correctAnswers += results.filter(\.isCorrect).count
        daily.totalTime += results.reduce(0) { $0 + $1.timeSpent }
        daily.sessionsCount += 1

        session.dailyProgress = daily
    }

    private static func createDailyProgress(
        date: Date,
        user: User,
        context: ModelContext
    ) -> DailyProgress {
        let daily = DailyProgress(date: date)
        daily.user = user
        context.insert(daily)
        return daily
    }

    // MARK: - Streak

    static func updateStreak(user: User) -> (streak: Int, isNew: Bool) {
        let calendar = Calendar.current

        if calendar.isDateInToday(user.lastActiveAt) {
            return (streak: user.currentStreak, isNew: false)
        }

        if calendar.isDateInYesterday(user.lastActiveAt) {
            user.currentStreak += 1
        } else {
            user.currentStreak = 1
        }

        if user.currentStreak > user.longestStreak {
            user.longestStreak = user.currentStreak
        }

        return (streak: user.currentStreak, isNew: true)
    }

    // MARK: - Achievements

    static func checkAchievements(
        user: User,
        session: Session,
        results: [ExerciseResult],
        context: ModelContext
    ) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        for achievement in user.achievements where !achievement.isUnlocked {
            guard let type = achievement.type else { continue }

            let (met, progress) = evaluateAchievement(
                type: type,
                user: user,
                session: session,
                results: results,
                currentProgress: achievement.progress
            )

            achievement.progress = max(achievement.progress, progress)

            if met {
                achievement.progress = achievement.target
                achievement.unlockedAt = Date()
                newlyUnlocked.append(achievement)
            }
        }

        return newlyUnlocked
    }

    private static func evaluateAchievement(
        type: AchievementType,
        user: User,
        session: Session,
        results: [ExerciseResult],
        currentProgress: Int = 0
    ) -> (met: Bool, progress: Int) {
        switch type {
        case .exercises10:
            return (user.totalExercises >= 10, min(user.totalExercises, 10))
        case .exercises50:
            return (user.totalExercises >= 50, min(user.totalExercises, 50))
        case .exercises100:
            return (user.totalExercises >= 100, min(user.totalExercises, 100))
        case .exercises500:
            return (user.totalExercises >= 500, min(user.totalExercises, 500))

        case .streak3:
            return (user.currentStreak >= 3, min(user.currentStreak, 3))
        case .streak7:
            return (user.currentStreak >= 7, min(user.currentStreak, 7))
        case .streak30:
            return (user.currentStreak >= 30, min(user.currentStreak, 30))

        case .perfect10:
            let isPerfectSession = results.allSatisfy(\.isCorrect) && results.count >= 10
            let newProgress = isPerfectSession ? currentProgress + 1 : currentProgress
            return (newProgress >= 10, newProgress)

        case .allStars:
            return (user.totalStars >= 100, min(user.totalStars, 100))

        case .speedDemon:
            let duration = session.duration ?? .infinity
            let met = results.count >= 10 && duration < 120
            return (met, met ? 1 : 0)

        case .earlyBird:
            let hour = Calendar.current.component(.hour, from: session.startTime)
            let met = hour < 8
            return (met, met ? 1 : 0)

        case .nightOwl:
            let hour = Calendar.current.component(.hour, from: session.startTime)
            let met = hour >= 20
            return (met, met ? 1 : 0)
        }
    }

    // MARK: - Initialization

    static func initializeAchievements(for user: User, context: ModelContext) {
        let existingTypes = Set(user.achievements.compactMap(\.type))

        for type in AchievementType.allCases where !existingTypes.contains(type) {
            let achievement = Achievement(type: type, target: type.defaultTarget)
            achievement.user = user
            context.insert(achievement)
        }

        // Fix perfect10: was incorrectly unlocked with progress=1, reset to track properly
        if let perfect10 = user.achievements.first(where: { $0.type == .perfect10 }),
           perfect10.isUnlocked, perfect10.progress <= 1 {
            perfect10.progress = 1
            perfect10.unlockedAt = nil
        }
    }
}
