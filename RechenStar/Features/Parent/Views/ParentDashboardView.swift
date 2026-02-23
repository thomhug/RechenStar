import SwiftUI
import SwiftData
import Charts

struct ParentDashboardView: View {
    let user: User
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var exerciseDetailsPage = 0

    private var sortedProgress: [DailyProgress] {
        user.progress.sorted { $0.date < $1.date }
    }

    private var weeklyProgress: [DailyProgress] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        return sortedProgress.filter { $0.date >= sevenDaysAgo }
    }

    private var weeklyAccuracy: Double {
        let totalCorrect = weeklyProgress.reduce(0) { $0 + $1.correctAnswers }
        let totalExercises = weeklyProgress.reduce(0) { $0 + $1.exercisesCompleted }
        guard totalExercises > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalExercises)
    }

    private var weeklyPlayTime: TimeInterval {
        weeklyProgress.reduce(0) { $0 + $1.totalTime }
    }

    private var weeklySessions: Int {
        weeklyProgress.reduce(0) { $0 + $1.sessionsCount }
    }

    private var weeklyExercises: Int {
        weeklyProgress.reduce(0) { $0 + $1.exercisesCompleted }
    }

    private var recentSessions: [Session] {
        weeklyProgress
            .flatMap(\.sessions)
            .sorted { ($0.endTime ?? $0.startTime) > ($1.endTime ?? $1.startTime) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    exercisesChart
                    accuracyChart
                    summaryCards
                    strengthsWeaknesses
                    focusExercises
                    exerciseDetails
                    overallStats
                    sessionsHistory
                    parentSettings
                }
                .padding(20)
            }
            .background(Color.appBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Elternbereich")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        onDismiss()
                    }
                }
            }
        }
    }

    // MARK: - Exercises Chart

    private struct DayData: Identifiable {
        let id = UUID()
        let date: Date
        let exercisesCompleted: Int
        let accuracy: Double
    }

    private var chartData: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -(6 - daysAgo), to: today)!
            let dayProgress = user.progress.first { calendar.isDate($0.date, inSameDayAs: date) }
            return DayData(
                date: date,
                exercisesCompleted: dayProgress?.exercisesCompleted ?? 0,
                accuracy: dayProgress?.accuracy ?? 0
            )
        }
    }

    private var exercisesChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aufgaben pro Tag")
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)

            Chart(chartData) { item in
                BarMark(
                    x: .value("Tag", item.date, unit: .day),
                    y: .value("Aufgaben", item.exercisesCompleted)
                )
                .foregroundStyle(Color.appSkyBlue.gradient)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 180)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
        )
    }

    // MARK: - Accuracy Chart

    private var accuracyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Genauigkeit")
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)

            let activeDays = chartData.filter { $0.exercisesCompleted > 0 }

            if activeDays.isEmpty {
                Text("Noch keine Daten vorhanden")
                    .font(AppFonts.body)
                    .foregroundColor(.appTextSecondary)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(activeDays) { item in
                    LineMark(
                        x: .value("Tag", item.date, unit: .day),
                        y: .value("Genauigkeit", item.accuracy * 100)
                    )
                    .foregroundStyle(Color.appGrassGreen)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Tag", item.date, unit: .day),
                        y: .value("Genauigkeit", item.accuracy * 100)
                    )
                    .foregroundStyle(Color.appGrassGreen)

                    AreaMark(
                        x: .value("Tag", item.date, unit: .day),
                        y: .value("Genauigkeit", item.accuracy * 100)
                    )
                    .foregroundStyle(Color.appGrassGreen.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v)%")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .frame(height: 140)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
        )
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        VStack(spacing: 12) {
            Text("Diese Woche")
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                StatCard(
                    title: "Genauigkeit",
                    value: String(format: "%.0f%%", weeklyAccuracy * 100),
                    icon: "target",
                    color: .appGrassGreen
                )
                StatCard(
                    title: "Spielzeit",
                    value: formatPlayTime(weeklyPlayTime),
                    icon: "clock.fill",
                    color: .appSkyBlue
                )
            }
            HStack(spacing: 12) {
                StatCard(
                    title: "Sessions",
                    value: "\(weeklySessions)",
                    icon: "play.circle.fill",
                    color: .appSunYellow
                )
                StatCard(
                    title: "Aufgaben",
                    value: "\(weeklyExercises)",
                    icon: "checkmark.circle.fill",
                    color: .appCoral
                )
            }
        }
    }

    // MARK: - Strengths & Weaknesses

    private struct CategoryStats {
        let category: ExerciseCategory
        let correct: Int
        let total: Int
        var accuracy: Double {
            total > 0 ? Double(correct) / Double(total) : 0
        }
    }

    /// Collect user's exercise records via relationship chain (avoids Session.id UUID bug)
    private func userExerciseRecords(since cutoff: Date? = nil) -> [ExerciseRecord] {
        var records: [ExerciseRecord] = []
        for daily in user.progress {
            for session in daily.sessions {
                for record in session.exerciseRecords {
                    if record.wasSkipped { continue }
                    if let cutoff = cutoff, record.date < cutoff { continue }
                    records.append(record)
                }
            }
        }
        return records
    }

    private var categoryStatsData: [CategoryStats] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        let weeklyRecords = userExerciseRecords(since: sevenDaysAgo)

        let grouped = Dictionary(grouping: weeklyRecords) { $0.category }

        return ExerciseCategory.allCases.compactMap { cat in
            let records = grouped[cat.rawValue] ?? []
            guard !records.isEmpty else { return nil }
            let correct = records.filter(\.isCorrect).count
            return CategoryStats(category: cat, correct: correct, total: records.count)
        }
    }

    private var strengthsWeaknesses: some View {
        let stats = categoryStatsData

        return VStack(alignment: .leading, spacing: 16) {
            Text("Stärken & Schwächen")
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)

            if stats.isEmpty {
                Text("Noch keine Daten diese Woche")
                    .font(AppFonts.body)
                    .foregroundColor(.appTextSecondary)
            } else {
                ForEach(stats, id: \.category) { stat in
                    operationRow(
                        label: stat.category.label,
                        icon: stat.category.icon,
                        correct: stat.correct,
                        total: stat.total,
                        accuracy: stat.accuracy
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
        )
    }

    private func operationRow(label: String, icon: String, correct: Int, total: Int, accuracy: Double) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(accuracy >= 0.8 ? .appGrassGreen : accuracy >= 0.5 ? .appSunYellow : .appCoral)
                    .frame(width: 28)
                Text(label)
                    .font(AppFonts.body)
                    .foregroundColor(.appTextPrimary)
                Spacer()
                if total > 0 {
                    Text("\(correct)/\(total)")
                        .font(AppFonts.caption)
                        .foregroundColor(.appTextSecondary)
                    Text(String(format: "%.0f%%", accuracy * 100))
                        .font(AppFonts.headline)
                        .foregroundColor(accuracy >= 0.8 ? .appGrassGreen : accuracy >= 0.5 ? .appSunYellow : .appCoral)
                } else {
                    Text("–")
                        .font(AppFonts.body)
                        .foregroundColor(.appTextSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            ProgressBarView(
                progress: accuracy,
                color: accuracy >= 0.8 ? .appGrassGreen : accuracy >= 0.5 ? .appSunYellow : .appCoral
            )
        }
    }

    // MARK: - Focus Exercises

    private var focusExercisesData: [ExerciseCategory: [(first: Int, second: Int)]] {
        let userRecords = userExerciseRecords()

        let recordData = userRecords.compactMap { record -> MetricsService.RecordData? in
            guard let category = ExerciseCategory(rawValue: record.category) else { return nil }
            return MetricsService.RecordData(
                category: category,
                exerciseSignature: record.exerciseSignature,
                firstNumber: record.firstNumber,
                secondNumber: record.secondNumber,
                isCorrect: record.isCorrect,
                date: record.date
            )
        }

        return MetricsService.computeMetrics(from: recordData)?.weakExercises ?? [:]
    }

    private var focusExercises: some View {
        let weakData = focusExercisesData

        return VStack(alignment: .leading, spacing: 16) {
            Text("Übungsfokus")
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)

            if weakData.isEmpty {
                Text("Keine schwachen Aufgaben — toll!")
                    .font(AppFonts.body)
                    .foregroundColor(.appTextSecondary)
            } else {
                ForEach(Array(weakData.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { category in
                    if let pairs = weakData[category], !pairs.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.appCoral)
                                    .frame(width: 24)
                                Text(category.label)
                                    .font(AppFonts.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.appTextPrimary)
                            }

                            let displayPairs = pairs.prefix(5).map { pair -> String in
                                let symbol = category.operationType.symbol
                                return "\(pair.first) \(symbol) \(pair.second)"
                            }
                            Text(displayPairs.joined(separator: ", "))
                                .font(AppFonts.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }

                Text("Diese Aufgaben werden automatisch häufiger gestellt")
                    .font(AppFonts.footnote)
                    .foregroundColor(.appTextSecondary)
                    .italic()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
        )
    }

    // MARK: - Exercise Details

    private struct ExerciseStats: Identifiable {
        let id: String // signature
        let displayText: String
        let correctCount: Int
        let totalCount: Int
        let avgTime: TimeInterval
        let lastThreeTimes: [TimeInterval]
    }

    private var exerciseStatsData: [ExerciseStats] {
        let userRecords = userExerciseRecords()

        // Group by category + numbers (ignoring format to avoid duplicates
        // like "1 + 1" appearing for both standard and gap-fill)
        let grouped = Dictionary(grouping: userRecords) { record in
            "\(record.category)_\(record.firstNumber)_\(record.secondNumber)"
        }

        return grouped.map { (key, records) in
            let correct = records.filter(\.isCorrect).count
            let total = records.count
            let avgTime = records.map(\.timeSpent).reduce(0, +) / Double(max(total, 1))
            let lastThree = records
                .sorted { $0.date > $1.date }
                .prefix(3)
                .map(\.timeSpent)
            let display = records.first?.displayText ?? key

            return ExerciseStats(
                id: key,
                displayText: display,
                correctCount: correct,
                totalCount: total,
                avgTime: avgTime,
                lastThreeTimes: Array(lastThree)
            )
        }
        .sorted { $0.totalCount != $1.totalCount ? $0.totalCount > $1.totalCount : $0.displayText < $1.displayText }
    }

    private let pageSize = 20

    private var exerciseDetails: some View {
        let stats = exerciseStatsData
        let totalPages = max(1, (stats.count + pageSize - 1) / pageSize)
        let page = min(exerciseDetailsPage, totalPages - 1)
        let startIndex = page * pageSize
        let endIndex = min(startIndex + pageSize, stats.count)
        let pageStats = startIndex < stats.count ? Array(stats[startIndex..<endIndex]) : []

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Aufgaben-Details")
                    .font(AppFonts.headline)
                    .foregroundColor(.appTextPrimary)
                Spacer()
                if stats.count > pageSize {
                    Text("\(page + 1)/\(totalPages)")
                        .font(AppFonts.caption)
                        .foregroundColor(.appTextSecondary)
                }
            }

            if stats.isEmpty {
                Text("Noch keine Daten vorhanden")
                    .font(AppFonts.body)
                    .foregroundColor(.appTextSecondary)
            } else {
                // Table header
                HStack(spacing: 0) {
                    Text("Aufgabe")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Richtig")
                        .frame(width: 55, alignment: .center)
                    Text("Falsch")
                        .frame(width: 50, alignment: .center)
                    Text("Ø Zeit")
                        .frame(width: 45, alignment: .center)
                    Text("Letzte 3")
                        .frame(width: 80, alignment: .trailing)
                }
                .font(AppFonts.caption)
                .foregroundColor(.appTextSecondary)

                Divider()

                ForEach(pageStats) { stat in
                    HStack(spacing: 0) {
                        Text(stat.displayText)
                            .font(AppFonts.body)
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("\(stat.correctCount)")
                            .font(AppFonts.body)
                            .foregroundColor(.appGrassGreen)
                            .frame(width: 55, alignment: .center)

                        Text("\(stat.totalCount - stat.correctCount)")
                            .font(AppFonts.body)
                            .foregroundColor(stat.totalCount - stat.correctCount > 0 ? .appCoral : .appTextSecondary)
                            .frame(width: 50, alignment: .center)

                        Text(formatSeconds(stat.avgTime))
                            .font(AppFonts.caption)
                            .foregroundColor(.appTextSecondary)
                            .frame(width: 45, alignment: .center)

                        Text(stat.lastThreeTimes.map { formatSeconds($0) }.joined(separator: ", "))
                            .font(AppFonts.caption)
                            .foregroundColor(.appTextSecondary)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                }

                if totalPages > 1 {
                    HStack {
                        Button {
                            exerciseDetailsPage = max(0, exerciseDetailsPage - 1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(page > 0 ? .appSkyBlue : .appTextSecondary.opacity(0.3))
                        }
                        .disabled(page == 0)

                        Spacer()

                        Button {
                            exerciseDetailsPage = min(totalPages - 1, exerciseDetailsPage + 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(page < totalPages - 1 ? .appSkyBlue : .appTextSecondary.opacity(0.3))
                        }
                        .disabled(page >= totalPages - 1)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
        )
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return String(format: "%.0fs", seconds)
        }
        return String(format: "%.0fm", seconds / 60)
    }

    // MARK: - Overall Stats

    private var overallStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gesamt")
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 12) {
                statRow(icon: "checkmark.circle.fill", color: .appGrassGreen,
                        label: "Aufgaben gelöst", value: "\(user.totalExercises)")
                statRow(icon: "star.fill", color: .appSunYellow,
                        label: "Sterne gesammelt", value: "\(user.totalStars)")
                statRow(icon: "flame.fill", color: .appOrange,
                        label: "Längster Streak", value: "\(user.longestStreak) Tage")
                statRow(icon: "calendar", color: .appSkyBlue,
                        label: "Dabei seit", value: formatMemberSince(user.createdAt))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
        )
    }

    private func statRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 28)
            Text(label)
                .font(AppFonts.body)
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Sessions History

    private var sessionsHistory: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Letzte Sessions")
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)

            if recentSessions.isEmpty {
                Text("Noch keine Sessions gespielt")
                    .font(AppFonts.body)
                    .foregroundColor(.appTextSecondary)
            } else {
                ForEach(recentSessions.prefix(10), id: \.id) { session in
                    sessionRow(session)
                    if session.id != recentSessions.prefix(10).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
        )
    }

    private func sessionRow(_ session: Session) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatSessionDate(session.endTime ?? session.startTime))
                    .font(AppFonts.body)
                    .foregroundColor(.appTextPrimary)
                Text("\(session.correctCount)/\(session.totalCount) richtig")
                    .font(AppFonts.caption)
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.appSunYellow)
                Text("\(session.starsEarned)")
                    .font(AppFonts.body)
                    .foregroundColor(.appTextPrimary)
            }
            accuracyBadge(session.accuracy)
        }
        .accessibilityElement(children: .combine)
    }

    private func accuracyBadge(_ accuracy: Double) -> some View {
        Text(String(format: "%.0f%%", accuracy * 100))
            .font(AppFonts.footnote)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(accuracy >= 0.9 ? Color.appGrassGreen :
                                accuracy >= 0.7 ? Color.appSkyBlue :
                                accuracy >= 0.5 ? Color.appSunYellow : Color.appCoral)
            )
    }

    // MARK: - Parent Settings

    private var parentSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Einstellungen")
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)

            if let prefs = user.preferences {
                Toggle("Pausen-Erinnerung", isOn: Binding(
                    get: { prefs.breakReminder },
                    set: { newValue in
                        prefs.breakReminder = newValue
                        try? modelContext.save()
                    }
                ))
                .tint(.appSkyBlue)

                if prefs.breakReminder {
                    HStack {
                        Text("Pause nach")
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { prefs.breakIntervalSeconds },
                            set: { newValue in
                                prefs.breakIntervalSeconds = newValue
                                try? modelContext.save()
                            }
                        )) {
                            Text("5 Min").tag(300)
                            Text("10 Min").tag(600)
                            Text("15 Min").tag(900)
                            Text("20 Min").tag(1200)
                            Text("30 Min").tag(1800)
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
        )
    }

    // MARK: - Helpers

    private func formatPlayTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 60 {
            return "\(minutes) Min"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }

    private func formatMemberSince(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    private func formatSessionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")

        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "'Heute,' HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "'Gestern,' HH:mm"
        } else {
            formatter.dateFormat = "E, d. MMM HH:mm"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)
            Text(title)
                .font(AppFonts.footnote)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
