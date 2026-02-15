import SwiftUI

struct AchievementsView: View {
    @Environment(AppState.self) private var appState

    private var sortedAchievements: [Achievement] {
        guard let user = appState.currentUser else { return [] }
        return user.achievements.sorted { a, b in
            if a.isUnlocked != b.isUnlocked { return a.isUnlocked }
            if a.isUnlocked, let dateA = a.unlockedAt, let dateB = b.unlockedAt {
                return dateA < dateB
            }
            return a.progressPercentage > b.progressPercentage
        }
    }

    private var unlockedCount: Int {
        appState.currentUser?.achievements.filter(\.isUnlocked).count ?? 0
    }

    private var totalCount: Int {
        appState.currentUser?.achievements.count ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if totalCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.appSunYellow)
                        Text("\(unlockedCount) von \(totalCount) freigeschaltet")
                            .font(AppFonts.body)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.bottom, 4)
                }

                ForEach(sortedAchievements, id: \.id) { achievement in
                    if let type = achievement.type {
                        AchievementCard(
                            achievement: AchievementData(
                                title: type.title,
                                description: type.description,
                                icon: type.icon,
                                progress: achievement.progressPercentage,
                                progressText: "\(achievement.progress)/\(achievement.target)"
                            ),
                            isUnlocked: achievement.isUnlocked
                        )
                    }
                }

                if sortedAchievements.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy")
                            .font(.system(size: 48))
                            .foregroundColor(.appTextSecondary.opacity(0.4))
                        Text("Spiele eine Runde, um Erfolge freizuschalten!")
                            .font(AppFonts.body)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    AchievementsView()
        .environment(AppState())
}
