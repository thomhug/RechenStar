import XCTest
import SwiftData
@testable import RechenStar

final class EngagementServiceTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: User.self, Achievement.self, DailyProgress.self, Session.self, UserPreferences.self, ExerciseRecord.self,
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

    @MainActor
    func testCategoryMasterCumulative() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let user = makeUser(container: container)

        // Simulate 3 sessions with 10 correct addition_10 exercises each = 30 total
        for _ in 0..<3 {
            let session = makeSession()
            context.insert(session)

            let daily = user.progress.first { Calendar.current.isDateInToday($0.date) }
                ?? {
                    let d = DailyProgress(date: Calendar.current.startOfDay(for: Date()))
                    d.user = user
                    context.insert(d)
                    return d
                }()
            session.dailyProgress = daily

            let results = makeResults(count: 10, allCorrect: true)
            for result in results {
                let record = ExerciseRecord(exercise: result.exercise, result: result)
                record.session = session
                context.insert(record)
            }
        }
        try context.save()

        // Verify: user now has 30 correct addition_10 records across 3 sessions
        let allRecords = user.progress.flatMap(\.sessions).flatMap(\.exerciseRecords)
        XCTAssertEqual(allRecords.count, 30, "Should have 30 cumulative records")

        // Now run checkAchievements — categoryMaster should unlock
        let checkSession = makeSession()
        context.insert(checkSession)
        let checkResults = makeResults(count: 1, allCorrect: true)
        user.totalExercises = 31

        let unlocked = EngagementService.checkAchievements(
            user: user, session: checkSession, results: checkResults, context: context
        )
        let types = unlocked.compactMap(\.type)
        XCTAssertTrue(types.contains(.categoryMaster),
            "categoryMaster should unlock with 30 correct addition_10 exercises across sessions")
    }

    @MainActor
    func testCrossSessionRevengeFlow() throws {
        // Simulates: session 1 has wrong answers → metrics detect weak exercises
        // → session 2 generates retry exercises with isRetry=true
        let container = try makeContainer()
        let context = container.mainContext
        let user = makeUser(container: container)

        // SESSION 1: Create exercises with some wrong answers
        let session1 = makeSession()
        context.insert(session1)
        let daily = DailyProgress(date: Calendar.current.startOfDay(for: Date()))
        daily.user = user
        context.insert(daily)
        session1.dailyProgress = daily

        // 3 wrong addition_10 exercises + 7 correct
        let wrongExercises = [
            Exercise(type: .addition, category: .addition_10, firstNumber: 2, secondNumber: 3),
            Exercise(type: .addition, category: .addition_10, firstNumber: 4, secondNumber: 1),
            Exercise(type: .addition, category: .addition_10, firstNumber: 3, secondNumber: 2),
        ]
        for ex in wrongExercises {
            let result = ExerciseResult(exercise: ex, userAnswer: 0, isCorrect: false, attempts: 2, timeSpent: 10)
            let record = ExerciseRecord(exercise: ex, result: result)
            record.session = session1
            context.insert(record)
        }
        for i in 0..<7 {
            let ex = Exercise(type: .subtraction, category: .subtraction_10, firstNumber: 5 + (i % 4), secondNumber: 1 + (i % 3))
            let result = ExerciseResult(exercise: ex, userAnswer: ex.correctAnswer, isCorrect: true, attempts: 1, timeSpent: 3)
            let record = ExerciseRecord(exercise: ex, result: result)
            record.session = session1
            context.insert(record)
        }
        try context.save()

        // Verify records are linked: user → progress → sessions → exerciseRecords
        let userSessionIDs = Set(user.progress.flatMap(\.sessions).map(\.id))
        XCTAssertTrue(userSessionIDs.contains(session1.id), "Session should be linked to user via daily progress")

        let allRecords = try context.fetchCount(FetchDescriptor<ExerciseRecord>())
        XCTAssertEqual(allRecords, 10, "Should have 10 records from session 1")

        // COMPUTE METRICS (same logic as HomeView.computeMetrics)
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        var descriptor = FetchDescriptor<ExerciseRecord>(
            predicate: #Predicate<ExerciseRecord> { $0.date >= cutoff }
        )
        descriptor.fetchLimit = 500
        let records = try context.fetch(descriptor)

        let userRecords = records.filter { record in
            guard let session = record.session else { return false }
            return userSessionIDs.contains(session.id)
        }
        XCTAssertEqual(userRecords.count, 10, "All 10 records should be linked to user sessions")

        let recordData = userRecords.compactMap { record -> MetricsService.RecordData? in
            guard let category = ExerciseCategory(rawValue: record.category) else { return nil }
            return MetricsService.RecordData(
                category: category,
                exerciseSignature: record.exerciseSignature,
                firstNumber: record.firstNumber,
                secondNumber: record.secondNumber,
                isCorrect: record.isCorrect
            )
        }

        let metrics = MetricsService.computeMetrics(from: recordData)
        XCTAssertNotNil(metrics, "Metrics should not be nil")

        let weakAddition = metrics!.weakExercises[.addition_10] ?? []
        XCTAssertEqual(weakAddition.count, 3, "Should have 3 weak addition exercises")

        // SESSION 2: Generate exercises with these metrics → should have isRetry exercises
        var retryCount = 0
        for _ in 0..<20 {
            let exercises = ExerciseGenerator.generateSession(
                count: 10,
                difficulty: .easy,
                categories: [.addition_10, .subtraction_10],
                metrics: metrics
            )
            retryCount += exercises.filter(\.isRetry).count
        }
        XCTAssertGreaterThan(retryCount, 0,
            "Should have generated at least some isRetry exercises across 20 sessions (got \(retryCount))")
    }

    @MainActor
    func testCategoryMasterNotUnlockedBelow20() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let user = makeUser(container: container)

        // Only 15 exercises — not enough
        let session = makeSession()
        context.insert(session)
        let daily = DailyProgress(date: Calendar.current.startOfDay(for: Date()))
        daily.user = user
        context.insert(daily)
        session.dailyProgress = daily

        let results = makeResults(count: 15, allCorrect: true)
        for result in results {
            let record = ExerciseRecord(exercise: result.exercise, result: result)
            record.session = session
            context.insert(record)
        }
        try context.save()

        let unlocked = EngagementService.checkAchievements(
            user: user, session: session, results: results, context: context
        )
        let types = unlocked.compactMap(\.type)
        XCTAssertFalse(types.contains(.categoryMaster),
            "categoryMaster should NOT unlock with only 15 exercises")
    }
}
