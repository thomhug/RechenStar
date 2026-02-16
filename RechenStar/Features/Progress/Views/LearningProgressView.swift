import SwiftUI
import SwiftData
import Charts

struct LearningProgressView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    private var user: User? { appState.currentUser }

    private var weeklyChartData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -(6 - daysAgo), to: today)!
            let dayProgress = user?.progress.first { calendar.isDate($0.date, inSameDayAs: date) }
            return (date: date, count: dayProgress?.exercisesCompleted ?? 0)
        }
    }

    private var currentSkillLevel: Difficulty {
        guard let prefs = user?.preferences else { return .veryEasy }
        if prefs.adaptiveDifficulty {
            let stats = categoryStatsData
            guard !stats.isEmpty else { return .veryEasy }
            let avgAccuracy = stats.map(\.accuracy).reduce(0, +) / Double(stats.count)
            if avgAccuracy >= 0.9 { return .hard }
            if avgAccuracy >= 0.7 { return .medium }
            if avgAccuracy >= 0.5 { return .easy }
            return .veryEasy
        }
        return Difficulty(rawValue: prefs.difficultyLevel) ?? .easy
    }

    private var categoryStatsData: [(category: ExerciseCategory, accuracy: Double)] {
        guard let user = user else { return [] }

        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        var descriptor = FetchDescriptor<ExerciseRecord>(
            predicate: #Predicate<ExerciseRecord> { $0.date >= cutoff }
        )
        descriptor.fetchLimit = 500

        guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else {
            return []
        }

        // Filter to current user's sessions only
        let userSessionIDs = Set(user.progress.flatMap(\.sessions).map(\.id))
        let userRecords = records.filter { record in
            guard let session = record.session else { return false }
            return userSessionIDs.contains(session.id)
        }

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

        guard let metrics = MetricsService.computeMetrics(from: recordData) else { return [] }

        return metrics.categoryAccuracy
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { (category: $0.key, accuracy: $0.value) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                badgeSection
                dailyGoalSection
                statsRow
                weeklyChart
                categoryStrengths
            }
            .padding(20)
        }
    }

    // MARK: - Badges

    private var badgeSection: some View {
        let total = user?.totalExercises ?? 0
        let level = Level.current(for: total)
        let progress = Level.progress(for: total)
        let nextExercises = level.nextLevelExercises
        let skill = currentSkillLevel

        return VStack(spacing: 12) {
            // Level badge (quantity)
            AppCard {
                HStack(spacing: 14) {
                    Image(level.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(level.title)
                            .font(AppFonts.headline)
                            .foregroundColor(.appTextPrimary)

                        if let next = nextExercises {
                            ProgressBarView(
                                progress: progress,
                                color: .appSunYellow,
                                height: 8
                            )
                            Text("Noch \(next - total) Aufgaben")
                                .font(AppFonts.footnote)
                                .foregroundColor(.appTextSecondary)
                        } else {
                            Text("Höchstes Level erreicht!")
                                .font(AppFonts.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.appSunYellow)
                        }
                    }
                }
            }

            // Skill badge (quality)
            AppCard {
                HStack(spacing: 14) {
                    Image(skill.skillImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(skill.skillTitle)
                            .font(AppFonts.headline)
                            .foregroundColor(.appTextPrimary)

                        Text(skill.label)
                            .font(AppFonts.footnote)
                            .foregroundColor(.appTextSecondary)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 8)
                            .background(
                                Capsule()
                                    .fill(skillColor(skill).opacity(0.15))
                            )
                    }

                    Spacer()
                }
            }
        }
    }

    private func skillColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .veryEasy: .appSkyBlue
        case .easy: .appGrassGreen
        case .medium: .appOrange
        case .hard: .purple
        }
    }

    // MARK: - Daily Goal

    private var dailyGoalSection: some View {
        let dailyGoal = user?.preferences?.dailyGoal ?? 20
        let calendar = Calendar.current
        let todayProgress = user?.progress.first { calendar.isDateInToday($0.date) }
        let completed = todayProgress?.exercisesCompleted ?? 0
        let fraction = min(Double(completed) / Double(dailyGoal), 1.0)
        let done = completed >= dailyGoal

        return AppCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: done ? "checkmark.circle.fill" : "target")
                        .font(.system(size: 28))
                        .foregroundColor(done ? .appGrassGreen : .appSkyBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tagesziel")
                            .font(AppFonts.headline)
                            .foregroundColor(.appTextPrimary)
                        Text("\(completed) von \(dailyGoal) Aufgaben")
                            .font(AppFonts.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    Spacer()
                    if done {
                        Text("Geschafft!")
                            .font(AppFonts.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.appGrassGreen)
                    }
                }
                ProgressBarView(
                    progress: fraction,
                    color: done ? .appGrassGreen : .appSkyBlue,
                    height: 10
                )
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            miniCard(
                icon: "checkmark.circle.fill",
                value: "\(user?.totalExercises ?? 0)",
                label: "Aufgaben",
                color: .appSuccess
            )
            miniCard(
                icon: "flame.fill",
                value: "\(user?.currentStreak ?? 0)",
                label: "Tage-Serie",
                color: .appOrange
            )
            miniCard(
                icon: "star.fill",
                value: "\(user?.totalStars ?? 0)",
                label: "Sterne",
                color: .appSunYellow
            )
        }
    }

    private func miniCard(icon: String, value: String, label: String, color: Color) -> some View {
        AppCard(padding: 12) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                Text(value)
                    .font(AppFonts.headline)
                    .foregroundColor(.appTextPrimary)
                Text(label)
                    .font(AppFonts.footnote)
                    .foregroundColor(.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Diese Woche")
                    .font(AppFonts.headline)
                    .foregroundColor(.appTextPrimary)

                Chart(weeklyChartData, id: \.date) { item in
                    BarMark(
                        x: .value("Tag", item.date, unit: .day),
                        y: .value("Aufgaben", item.count)
                    )
                    .foregroundStyle(Color.appSkyBlue.gradient)
                    .cornerRadius(6)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .frame(height: 150)
            }
        }
    }

    // MARK: - Category Strengths

    private var categoryStrengths: some View {
        let stats = categoryStatsData

        return Group {
            if !stats.isEmpty {
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Deine Stärken")
                            .font(AppFonts.headline)
                            .foregroundColor(.appTextPrimary)

                        ForEach(stats, id: \.category) { stat in
                            HStack(spacing: 10) {
                                Image(systemName: stat.category.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(strengthColor(stat.accuracy))
                                    .frame(width: 24)
                                Text(stat.category.label)
                                    .font(AppFonts.body)
                                    .foregroundColor(.appTextPrimary)
                                Spacer()
                                Text(String(format: "%.0f%%", stat.accuracy * 100))
                                    .font(AppFonts.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(strengthColor(stat.accuracy))
                            }
                            ProgressBarView(
                                progress: stat.accuracy,
                                color: strengthColor(stat.accuracy)
                            )
                        }
                    }
                }
            }
        }
    }

    private func strengthColor(_ accuracy: Double) -> Color {
        accuracy >= 0.8 ? .appGrassGreen : accuracy >= 0.5 ? .appSunYellow : .appCoral
    }
}

#Preview {
    LearningProgressView()
        .environment(AppState())
        .modelContainer(for: [User.self, Session.self, DailyProgress.self, Achievement.self, UserPreferences.self, ExerciseRecord.self], inMemory: true)
}
