import SwiftUI

struct AchievementsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AchievementCard(
                    achievement: AchievementData(
                        title: "Erste Schritte",
                        description: "Löse 10 Aufgaben",
                        icon: "10.circle.fill",
                        progress: 0.0
                    ),
                    isUnlocked: false
                )

                AchievementCard(
                    achievement: AchievementData(
                        title: "Halbes Hundert",
                        description: "Löse 50 Aufgaben",
                        icon: "50.circle.fill",
                        progress: 0.0
                    ),
                    isUnlocked: false
                )

                AchievementCard(
                    achievement: AchievementData(
                        title: "Hunderter-Held",
                        description: "Löse 100 Aufgaben",
                        icon: "medal.fill",
                        progress: 0.0
                    ),
                    isUnlocked: false
                )
            }
            .padding(20)
        }
    }
}

#Preview {
    AchievementsView()
}
