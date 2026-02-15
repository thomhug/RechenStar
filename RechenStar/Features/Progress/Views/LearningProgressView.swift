import SwiftUI

struct LearningProgressView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ProgressCard(
                    title: "Heutige Aufgaben",
                    value: "\(appState.currentUser?.totalExercises ?? 0)",
                    subtitle: "Gesamt gelöst",
                    icon: "checkmark.circle.fill",
                    color: .appSuccess
                )

                ProgressCard(
                    title: "Aktuelle Serie",
                    value: "\(appState.currentUser?.currentStreak ?? 0) Tage",
                    subtitle: "Längste: \(appState.currentUser?.longestStreak ?? 0) Tage",
                    icon: "flame.fill",
                    color: .appOrange
                )

                ProgressCard(
                    title: "Sterne",
                    value: "\(appState.currentUser?.totalStars ?? 0)",
                    subtitle: "Weiter so!",
                    icon: "star.fill",
                    color: .appSunYellow
                )
            }
            .padding(20)
        }
    }
}

#Preview {
    LearningProgressView()
        .environment(AppState())
}
