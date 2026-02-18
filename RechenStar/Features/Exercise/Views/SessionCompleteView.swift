import SwiftUI

struct SessionCompleteView: View {
    @Environment(ThemeManager.self) private var themeManager
    let results: [ExerciseResult]
    let sessionLength: Int
    var unlockedAchievements: [Achievement] = []
    var currentStreak: Int = 0
    var isNewStreak: Bool = false
    var dailyGoalReached: Bool = false
    var newLevel: Level? = nil
    let onDismiss: () -> Void

    @State private var starsVisible = 0

    private var attemptedResults: [ExerciseResult] {
        results.filter { !$0.wasSkipped }
    }

    private var totalStars: Int {
        results.reduce(0) { $0 + $1.stars }
    }

    private var maxStars: Int {
        sessionLength * 3
    }

    private var correctCount: Int {
        attemptedResults.filter(\.isCorrect).count
    }

    private var accuracy: Double {
        guard !attemptedResults.isEmpty else { return 0 }
        return Double(correctCount) / Double(attemptedResults.count)
    }

    private var totalTime: TimeInterval {
        attemptedResults.reduce(0) { $0 + $1.timeSpent }
    }

    private var formattedTime: String {
        let seconds = Int(totalTime)
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d Min", minutes, secs)
        }
        return "\(secs) Sek"
    }

    private var motivationText: String {
        switch accuracy {
        case 0.9...: return "Fantastisch!"
        case 0.7..<0.9: return "Super gemacht!"
        case 0.5..<0.7: return "Gut gemacht!"
        default: return "Toll, dass du geübt hast!"
        }
    }

    private var skippedCount: Int {
        results.filter(\.wasSkipped).count
    }

    private var categoryGroups: [(category: ExerciseCategory, correct: Int, total: Int)] {
        let grouped = Dictionary(grouping: attemptedResults) { $0.exercise.category }
        return grouped.map { (category, catResults) in
            let correct = catResults.filter(\.isCorrect).count
            return (category: category, correct: correct, total: catResults.count)
        }
        .sorted { $0.category.rawValue < $1.category.rawValue }
    }

    private var motivationIcon: String {
        switch accuracy {
        case 0.9...: return "star.circle.fill"
        case 0.7..<0.9: return "hand.thumbsup.fill"
        case 0.5..<0.7: return "face.smiling.fill"
        default: return "heart.fill"
        }
    }

    private var showConfetti: Bool {
        accuracy >= 0.6 || !unlockedAchievements.isEmpty || dailyGoalReached || newLevel != nil
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    Text("Geschafft!")
                        .font(AppFonts.display)
                        .foregroundColor(.appSkyBlue)

                    // Stars
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            ForEach(0..<min(totalStars, 5), id: \.self) { index in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.appSunYellow)
                                    .scaleEffect(index < starsVisible ? 1.0 : 0.0)
                                    .animation(
                                        .spring(duration: 0.4, bounce: 0.5)
                                            .delay(Double(index) * 0.15),
                                        value: starsVisible
                                    )
                            }
                        }

                        Text("\(totalStars) von \(maxStars) Sternen")
                            .font(AppFonts.headline)
                            .foregroundColor(.appTextPrimary)
                    }

                    // Level Up
                    if let newLevel {
                        AppCard(backgroundColor: .appSkyBlue.opacity(0.12)) {
                            VStack(spacing: 12) {
                                Image(newLevel.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)

                                Text("Level Up!")
                                    .font(AppFonts.title)
                                    .foregroundColor(.appSkyBlue)
                                Text("Du bist jetzt \(newLevel.title)!")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.appTextPrimary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.appSkyBlue.opacity(0.4), lineWidth: 2)
                        )
                        .padding(.horizontal, 20)
                    }

                    // Stats
                    HStack(spacing: 12) {
                        AppCard(padding: 12) {
                            VStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.appSuccess)
                                Text(skippedCount > 0
                                    ? "\(correctCount)/\(attemptedResults.count)"
                                    : "\(correctCount)/\(results.count)")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.appTextPrimary)
                                if skippedCount > 0 {
                                    Text("\(skippedCount) übersprungen")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.appSunYellow)
                                } else {
                                    Text("Richtig")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }

                        AppCard(padding: 12) {
                            VStack(spacing: 6) {
                                Image(systemName: "percent")
                                    .font(.system(size: 24))
                                    .foregroundColor(.appSkyBlue)
                                Text("\(Int(accuracy * 100))%")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.appTextPrimary)
                                Text("Genauigkeit")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        AppCard(padding: 12) {
                            VStack(spacing: 6) {
                                Image(systemName: "timer")
                                    .font(.system(size: 24))
                                    .foregroundColor(.appSunYellow)
                                Text(formattedTime)
                                    .font(AppFonts.headline)
                                    .foregroundColor(.appTextPrimary)
                                Text("Zeit")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Motivation
                    VStack(spacing: 8) {
                        AppCard {
                            HStack(spacing: 12) {
                                Image(systemName: motivationIcon)
                                    .font(.system(size: 36))
                                    .foregroundColor(.appSunYellow)
                                Text(motivationText)
                                    .font(AppFonts.title)
                                    .foregroundColor(.appTextPrimary)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        if accuracy < 0.7 {
                            Text("Du hast \(correctCount) Aufgaben richtig gelöst — das ist ein guter Anfang!")
                                .font(AppFonts.caption)
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Daily Goal
                    if dailyGoalReached {
                        AppCard(backgroundColor: .appSunYellow.opacity(0.12)) {
                            HStack(spacing: 12) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.appSunYellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tagesziel geschafft!")
                                        .font(AppFonts.headline)
                                        .foregroundColor(.appTextPrimary)
                                    Text("Du hast dein Ziel für heute erreicht.")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                                Spacer()
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.appSunYellow.opacity(0.4), lineWidth: 2)
                        )
                        .padding(.horizontal, 20)
                    }

                    // Category Breakdown
                    if categoryGroups.count > 1 {
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Nach Kategorie")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.appTextPrimary)

                                ForEach(categoryGroups, id: \.category) { group in
                                    HStack(spacing: 10) {
                                        Image(systemName: group.category.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(categoryColor(correct: group.correct, total: group.total))
                                            .frame(width: 24)
                                        Text(group.category.label)
                                            .font(AppFonts.body)
                                            .foregroundColor(.appTextPrimary)
                                        Spacer()
                                        Text("\(group.correct)/\(group.total) richtig")
                                            .font(AppFonts.caption)
                                            .foregroundColor(.appTextSecondary)
                                        categoryAccuracyBadge(correct: group.correct, total: group.total)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Streak
                    if currentStreak > 1 {
                        AppCard(backgroundColor: .appOrange.opacity(0.1)) {
                            HStack(spacing: 12) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.appOrange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(currentStreak) Tage am Stück!")
                                        .font(AppFonts.headline)
                                        .foregroundColor(.appTextPrimary)
                                    if isNewStreak {
                                        Text("Weiter so!")
                                            .font(AppFonts.caption)
                                            .foregroundColor(.appOrange)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Newly unlocked achievements
                    if !unlockedAchievements.isEmpty {
                        VStack(spacing: 12) {
                            Text("Neue Erfolge!")
                                .font(AppFonts.headline)
                                .foregroundColor(.appSunYellow)

                            ForEach(unlockedAchievements, id: \.id) { achievement in
                                if let type = achievement.type {
                                    AppCard(
                                        backgroundColor: .appSunYellow.opacity(0.08)
                                    ) {
                                        HStack(spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.appSunYellow.opacity(0.2))
                                                    .frame(width: 54, height: 54)
                                                Image(systemName: type.icon)
                                                    .font(.system(size: 26, weight: .bold))
                                                    .foregroundColor(.appSunYellow)
                                            }

                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack(spacing: 6) {
                                                    Text(type.title)
                                                        .font(AppFonts.headline)
                                                        .foregroundColor(.appTextPrimary)
                                                    Text("Neu!")
                                                        .font(AppFonts.footnote)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 2)
                                                        .background(
                                                            Capsule().fill(Color.appSunYellow)
                                                        )
                                                }
                                                Text(type.description)
                                                    .font(AppFonts.caption)
                                                    .foregroundColor(.appTextSecondary)
                                            }
                                            Spacer()
                                        }
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.appSunYellow.opacity(0.4), lineWidth: 2)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 20)

                    AppButton(title: "Weiter", variant: .primary, icon: "house.fill") {
                        onDismiss()
                    }
                    .accessibilityIdentifier("done-button")

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(Color.appBackgroundGradient.ignoresSafeArea())

            if showConfetti && !themeManager.reducedMotion {
                ConfettiView()
            }
        }
        .accessibilityIdentifier("session-complete")
        .onAppear {
            if !themeManager.reducedMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    starsVisible = min(totalStars, 5)
                }
            } else {
                starsVisible = min(totalStars, 5)
            }
            if themeManager.soundEnabled {
                SoundService.playSessionComplete()
                if !unlockedAchievements.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        SoundService.playAchievement()
                    }
                }
            }
        }
    }

    private func categoryColor(correct: Int, total: Int) -> Color {
        let acc = total > 0 ? Double(correct) / Double(total) : 0
        return acc >= 0.8 ? .appGrassGreen : acc >= 0.5 ? .appSunYellow : .appCoral
    }

    private func categoryAccuracyBadge(correct: Int, total: Int) -> some View {
        let acc = total > 0 ? Double(correct) / Double(total) : 0
        return Text(String(format: "%.0f%%", acc * 100))
            .font(AppFonts.footnote)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(categoryColor(correct: correct, total: total))
            )
    }
}
