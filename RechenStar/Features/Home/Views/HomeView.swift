import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var exerciseFlowState: ExerciseFlowState?

    enum ExerciseFlowState: Identifiable {
        case exercising
        case completed(results: [ExerciseResult], sessionLength: Int)

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

            Spacer()
        }
        .padding(20)
        .fullScreenCover(item: $exerciseFlowState) { state in
            switch state {
            case .exercising:
                ExerciseView { results in
                    let sessionLength = results.count
                    exerciseFlowState = .completed(
                        results: results,
                        sessionLength: sessionLength
                    )
                } onCancel: {
                    exerciseFlowState = nil
                }

            case .completed(let results, let sessionLength):
                SessionCompleteView(
                    results: results,
                    sessionLength: sessionLength
                ) {
                    saveSession(results: results)
                    exerciseFlowState = nil
                }
            }
        }
    }

    private func saveSession(results: [ExerciseResult]) {
        let session = Session()
        session.endTime = Date()
        session.isCompleted = true
        session.sessionGoal = results.count
        session.correctCount = results.filter(\.isCorrect).count
        session.totalCount = results.count
        session.starsEarned = results.reduce(0) { $0 + $1.stars }

        modelContext.insert(session)

        if let user = appState.currentUser {
            user.totalExercises += results.count
            user.totalStars += session.starsEarned
        }

        try? modelContext.save()
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .modelContainer(for: [User.self, Session.self, DailyProgress.self, Achievement.self, UserPreferences.self], inMemory: true)
}
