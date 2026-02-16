import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var exerciseFlowState: ExerciseFlowState?

    enum ExerciseFlowState: Identifiable {
        case exercising
        case completed(results: [ExerciseResult], sessionLength: Int, engagement: EngagementResult)

        var id: String {
            switch self {
            case .exercising: return "exercising"
            case .completed: return "completed"
            }
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("RechenStar")
                .font(AppFonts.display)
                .foregroundColor(.appSkyBlue)

            if let user = appState.currentUser {
                Text("Hallo, \(user.name)!")
                    .font(AppFonts.headline)
                    .foregroundColor(.appTextPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.appSunYellow)
                    Text("\(user.totalStars) Sterne gesammelt")
                        .font(AppFonts.body)
                        .foregroundColor(.appTextSecondary)
                }

                dailyGoalSection(user: user)
            }

            Spacer()

            AppButton(
                title: "Spielen",
                variant: .primary,
                icon: "play.fill"
            ) {
                exerciseFlowState = .exercising
            }
            .accessibilityIdentifier("play-button")

            Spacer()
        }
        .padding(20)
        .fullScreenCover(item: $exerciseFlowState) { state in
            switch state {
            case .exercising:
                ExerciseView(
                    sessionLength: appState.currentUser?.preferences?.sessionLength ?? 10,
                    difficulty: difficultyFromPreferences(),
                    categories: categoriesFromPreferences(),
                    metrics: computeMetrics(),
                    adaptiveDifficulty: appState.currentUser?.preferences?.adaptiveDifficulty ?? true
                ) { results in
                    let engagement = saveSession(results: results)
                    exerciseFlowState = .completed(
                        results: results,
                        sessionLength: results.count,
                        engagement: engagement
                    )
                } onCancel: { partialResults in
                    if !partialResults.isEmpty {
                        _ = saveSession(results: partialResults)
                    }
                    exerciseFlowState = nil
                }

            case .completed(let results, let sessionLength, let engagement):
                SessionCompleteView(
                    results: results,
                    sessionLength: sessionLength,
                    unlockedAchievements: engagement.newlyUnlockedAchievements,
                    currentStreak: engagement.currentStreak,
                    isNewStreak: engagement.isNewStreak
                ) {
                    exerciseFlowState = nil
                }
            }
        }
    }

    private func saveSession(results: [ExerciseResult]) -> EngagementResult {
        let session = Session()
        session.endTime = Date()
        session.isCompleted = true
        session.sessionGoal = results.count
        session.correctCount = results.filter(\.isCorrect).count
        session.totalCount = results.count
        session.starsEarned = results.reduce(0) { $0 + $1.stars }

        let additionResults = results.filter { $0.exercise.type == .addition }
        let subtractionResults = results.filter { $0.exercise.type == .subtraction }
        session.additionTotal = additionResults.count
        session.additionCorrect = additionResults.filter(\.isCorrect).count
        session.subtractionTotal = subtractionResults.count
        session.subtractionCorrect = subtractionResults.filter(\.isCorrect).count

        modelContext.insert(session)

        for result in results {
            let record = ExerciseRecord(exercise: result.exercise, result: result)
            record.session = session
            modelContext.insert(record)
        }

        if let user = appState.currentUser {
            user.totalExercises += results.count
            user.totalStars += session.starsEarned

            let engagement = EngagementService.processSession(
                results: results,
                session: session,
                user: user,
                context: modelContext
            )
            return engagement
        }

        return EngagementResult(
            newlyUnlockedAchievements: [],
            currentStreak: 0,
            isNewStreak: false
        )
    }

    private func difficultyFromPreferences() -> Difficulty {
        guard let prefs = appState.currentUser?.preferences else { return .easy }
        if prefs.adaptiveDifficulty { return .easy }
        return Difficulty(rawValue: prefs.difficultyLevel) ?? .easy
    }

    private func dailyGoalSection(user: User) -> some View {
        let dailyGoal = user.preferences?.dailyGoal ?? 20
        let calendar = Calendar.current
        let todayProgress = user.progress.first { calendar.isDateInToday($0.date) }
        let completed = todayProgress?.exercisesCompleted ?? 0
        let fraction = min(Double(completed) / Double(dailyGoal), 1.0)
        let done = completed >= dailyGoal

        return VStack(spacing: 8) {
            HStack {
                Image(systemName: done ? "checkmark.circle.fill" : "target")
                    .foregroundColor(done ? .appGrassGreen : .appSkyBlue)
                Text("Tagesziel: \(completed)/\(dailyGoal)")
                    .font(AppFonts.caption)
                    .foregroundColor(.appTextSecondary)
            }
            ProgressBarView(
                progress: fraction,
                color: done ? .appGrassGreen : .appSkyBlue,
                height: 8
            )
            .frame(maxWidth: 200)
        }
        .padding(.top, 8)
    }

    private func categoriesFromPreferences() -> [ExerciseCategory] {
        guard let prefs = appState.currentUser?.preferences else {
            return [.addition_10, .subtraction_10]
        }
        let cats = prefs.enabledCategories
        return cats.isEmpty ? [.addition_10, .subtraction_10] : cats
    }

    private func computeMetrics() -> ExerciseMetrics? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        var descriptor = FetchDescriptor<ExerciseRecord>(
            predicate: #Predicate<ExerciseRecord> { $0.date >= cutoff }
        )
        descriptor.fetchLimit = 500

        guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else {
            return nil
        }

        // Category accuracy
        var categoryGroups: [ExerciseCategory: (correct: Int, total: Int)] = [:]
        for record in records {
            guard let category = ExerciseCategory(rawValue: record.category) else { continue }
            var group = categoryGroups[category, default: (correct: 0, total: 0)]
            group.total += 1
            if record.isCorrect { group.correct += 1 }
            categoryGroups[category] = group
        }

        var categoryAccuracy: [ExerciseCategory: Double] = [:]
        for (category, group) in categoryGroups {
            categoryAccuracy[category] = Double(group.correct) / Double(group.total)
        }

        // Weak exercises: accuracy < 0.6 with at least 2 attempts
        var signatureGroups: [String: (correct: Int, total: Int, category: ExerciseCategory, first: Int, second: Int)] = [:]
        for record in records {
            guard let category = ExerciseCategory(rawValue: record.category) else { continue }
            let sig = record.exerciseSignature
            var group = signatureGroups[sig, default: (correct: 0, total: 0, category: category, first: record.firstNumber, second: record.secondNumber)]
            group.total += 1
            if record.isCorrect { group.correct += 1 }
            signatureGroups[sig] = group
        }

        var weakExercises: [ExerciseCategory: [(first: Int, second: Int)]] = [:]
        for (_, group) in signatureGroups {
            guard group.total >= 2 else { continue }
            let accuracy = Double(group.correct) / Double(group.total)
            if accuracy < 0.6 {
                weakExercises[group.category, default: []].append((first: group.first, second: group.second))
            }
        }

        return ExerciseMetrics(categoryAccuracy: categoryAccuracy, weakExercises: weakExercises)
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .modelContainer(for: [User.self, Session.self, DailyProgress.self, Achievement.self, UserPreferences.self], inMemory: true)
}
