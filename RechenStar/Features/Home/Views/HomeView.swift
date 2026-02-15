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
                    categories: categoriesFromPreferences()
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

    private func categoriesFromPreferences() -> [ExerciseCategory] {
        guard let prefs = appState.currentUser?.preferences else {
            return [.addition_10, .subtraction_10]
        }
        let cats = prefs.enabledCategories
        return cats.isEmpty ? [.addition_10, .subtraction_10] : cats
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .modelContainer(for: [User.self, Session.self, DailyProgress.self, Achievement.self, UserPreferences.self], inMemory: true)
}
