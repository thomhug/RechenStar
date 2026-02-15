import XCTest
import SwiftData
@testable import RechenStar

final class EngagementServiceTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: User.self, Achievement.self, DailyProgress.self, Session.self, UserPreferences.self,
            configurations: config
        )
    }

    @MainActor
    private func makeUser(container: ModelContainer) -> User {
        let context = container.mainContext
        let user = User(name: "Noah")
        context.insert(user)
        EngagementService.initializeAchievements(for: user, context: context)
        try? context.save()
        return user
    }

    private func makeResults(count: Int = 10, allCorrect: Bool = true) -> [ExerciseResult] {
        (0..<count).map { i in
            ExerciseResult(
                exercise: Exercise(type: .addition, category: .addition_10, firstNumber: 1 + (i % 5), secondNumber: 1),
                userAnswer: allCorrect ? (2 + (i % 5)) : 99,
                isCorrect: allCorrect,
                attempts: 1,
                timeSpent: 5.0
            )
        }
    }

    private func makeSession(duration: TimeInterval = 60) -> Session {
        let session = Session()
        session.startTime = Date()
        session.endTime = session.startTime.addingTimeInterval(duration)
        return session
    }

    // MARK: - Streak Tests

    @MainActor
    func testStreakIncrementsFromYesterday() throws {
        let container = try makeContainer()
        let user = makeUser(container: container)
        user.currentStreak = 3
        user.lastActiveAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let result = EngagementService.updateStreak(user: user)
        XCTAssertEqual(result.streak, 4)
        XCTAssertTrue(result.isNew)
        XCTAssertEqual(user.currentStreak, 4)
    }

    @MainActor
    func testStreakResetsAfterGap() throws {
        let container = try makeContainer()
        let user = makeUser(container: container)
        user.currentStreak = 5
        user.lastActiveAt = Calendar.current.date(byAdding: .day, value: -2, to: Date())!

        let result = EngagementService.updateStreak(user: user)
        XCTAssertEqual(result.streak, 1)
        XCTAssertEqual(user.currentStreak, 1)
    }

    @MainActor
    func testStreakSameDayNoChange() throws {
        let container = try makeContainer()
        let user = makeUser(container: container)
        user.currentStreak = 3
        user.lastActiveAt = Date()

        let result = EngagementService.updateStreak(user: user)
        XCTAssertEqual(result.streak, 3)
        XCTAssertFalse(result.isNew)
    }

    @MainActor
    func testLongestStreakUpdated() throws {
        let container = try makeContainer()
        let user = makeUser(container: container)
        user.currentStreak = 5
        user.longestStreak = 5
        user.lastActiveAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        _ = EngagementService.updateStreak(user: user)
        XCTAssertEqual(user.longestStreak, 6)
    }

    // MARK: - Achievement Tests

    @MainActor
    func testAchievementExercises10() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let user = makeUser(container: container)
        user.totalExercises = 10

        let session = makeSession()
        context.insert(session)
        let results = makeResults(count: 10)

        let unlocked = EngagementService.checkAchievements(
            user: user, session: session, results: results, context: context
        )

        let types = unlocked.compactMap(\.type)
        XCTAssertTrue(types.contains(.exercises10))
    }

    @MainActor
    func testAchievementPerfect10Incremental() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let user = makeUser(container: container)

        let perfect10 = user.achievements.first { $0.type == .perfect10 }

        // One perfect session → progress 1/10, not yet unlocked
        let session1 = makeSession()
        context.insert(session1)
        let results1 = makeResults(count: 10, allCorrect: true)
        let unlocked1 = EngagementService.checkAchievements(
            user: user, session: session1, results: results1, context: context
        )
        XCTAssertFalse(unlocked1.compactMap(\.type).contains(.perfect10))
        XCTAssertEqual(perfect10?.progress, 1)

        // After 9 more perfect sessions → unlocked at 10/10
        for i in 2...10 {
            let session = makeSession()
            context.insert(session)
            let results = makeResults(count: 10, allCorrect: true)
            _ = EngagementService.checkAchievements(
                user: user, session: session, results: results, context: context
            )
            XCTAssertEqual(perfect10?.progress, i)
        }
        XCTAssertTrue(perfect10?.isUnlocked ?? false)
    }

    @MainActor
    func testAchievementSpeedDemon() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let user = makeUser(container: container)

        let session = makeSession(duration: 90) // < 120s
        context.insert(session)
        let results = makeResults(count: 10)

        let unlocked = EngagementService.checkAchievements(
            user: user, session: session, results: results, context: context
        )

        let types = unlocked.compactMap(\.type)
        XCTAssertTrue(types.contains(.speedDemon))
    }

    @MainActor
    func testAchievementProgressTracked() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let user = makeUser(container: container)
        user.totalExercises = 7

        let session = makeSession()
        context.insert(session)
        let results = makeResults(count: 5, allCorrect: false)

        _ = EngagementService.checkAchievements(
            user: user, session: session, results: results, context: context
        )

        let exercises10 = user.achievements.first { $0.type == .exercises10 }
        XCTAssertEqual(exercises10?.progress, 7)
        XCTAssertFalse(exercises10?.isUnlocked ?? true)
    }
}
