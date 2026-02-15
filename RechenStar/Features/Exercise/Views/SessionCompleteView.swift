import SwiftUI

struct SessionCompleteView: View {
    let results: [ExerciseResult]
    let sessionLength: Int
    var unlockedAchievements: [Achievement] = []
    var currentStreak: Int = 0
    var isNewStreak: Bool = false
    let onDismiss: () -> Void

    private var totalStars: Int {
        results.reduce(0) { $0 + $1.stars }
    }

    private var maxStars: Int {
        sessionLength * 3
    }

    private var correctCount: Int {
        results.filter(\.isCorrect).count
    }

    private var accuracy: Double {
        guard !results.isEmpty else { return 0 }
        return Double(correctCount) / Double(results.count)
    }

    private var motivationText: String {
        switch accuracy {
        case 0.9...: return "Fantastisch!"
        case 0.7..<0.9: return "Super!"
        case 0.5..<0.7: return "Gut gemacht!"
        default: return "Nicht aufgeben!"
        }
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
        accuracy >= 0.9 || !unlockedAchievements.isEmpty
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
                            ForEach(0..<min(totalStars, 5), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.appSunYellow)
                            }
                        }

                        Text("\(totalStars) von \(maxStars) Sternen")
                            .font(AppFonts.headline)
                            .foregroundColor(.appTextPrimary)
                    }

                    // Stats
                    HStack(spacing: 16) {
                        AppCard(padding: 16) {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.appSuccess)
                                Text("\(correctCount)/\(results.count)")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.appTextPrimary)
                                Text("Richtig")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        AppCard(padding: 16) {
                            VStack(spacing: 8) {
                                Image(systemName: "percent")
                                    .font(.system(size: 28))
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
                    }
                    .padding(.horizontal, 20)

                    // Motivation
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
                    .padding(.horizontal, 20)

                    // Streak
                    if currentStreak > 1 {
                        AppCard(backgroundColor: .appOrange.opacity(0.1)) {
                            HStack(spacing: 12) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.appOrange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(currentStreak) Tage am Stueck!")
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

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(Color.appBackgroundGradient.ignoresSafeArea())

            if showConfetti {
                ConfettiView()
            }
        }
    }
}
