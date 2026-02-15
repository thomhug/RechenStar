import SwiftUI
import SwiftData
import Charts

struct ParentDashboardView: View {
    let user: User
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext

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

    private var strengthsWeaknesses: some View {
        let allSessions = weeklyProgress.flatMap(\.sessions)
        let addTotal = allSessions.reduce(0) { $0 + $1.additionTotal }
        let addCorrect = allSessions.reduce(0) { $0 + $1.additionCorrect }
        let subTotal = allSessions.reduce(0) { $0 + $1.subtractionTotal }
        let subCorrect = allSessions.reduce(0) { $0 + $1.subtractionCorrect }
        let addAccuracy = addTotal > 0 ? Double(addCorrect) / Double(addTotal) : 0
        let subAccuracy = subTotal > 0 ? Double(subCorrect) / Double(subTotal) : 0

        return VStack(alignment: .leading, spacing: 16) {
            Text("Staerken & Schwaechen")
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)

            if addTotal == 0 && subTotal == 0 {
                Text("Noch keine Daten diese Woche")
                    .font(AppFonts.body)
                    .foregroundColor(.appTextSecondary)
            } else {
                operationRow(
                    label: "Addition",
                    icon: "plus.circle.fill",
                    correct: addCorrect,
                    total: addTotal,
                    accuracy: addAccuracy
                )
                operationRow(
                    label: "Subtraktion",
                    icon: "minus.circle.fill",
                    correct: subCorrect,
                    total: subTotal,
                    accuracy: subAccuracy
                )
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

    // MARK: - Overall Stats

    private var overallStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gesamt")
                .font(AppFonts.headline)
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 12) {
                statRow(icon: "checkmark.circle.fill", color: .appGrassGreen,
                        label: "Aufgaben geloest", value: "\(user.totalExercises)")
                statRow(icon: "star.fill", color: .appSunYellow,
                        label: "Sterne gesammelt", value: "\(user.totalStars)")
                statRow(icon: "flame.fill", color: .appOrange,
                        label: "Laengster Streak", value: "\(user.longestStreak) Tage")
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
