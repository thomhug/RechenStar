import SwiftUI
import SwiftData
import Charts

struct ParentDashboardView: View {
    let user: User
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext

    private var weeklyProgress: [DailyProgress] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        return user.progress.filter { $0.date >= sevenDaysAgo }
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    weeklyChart
                    summaryCards
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

    // MARK: - Weekly Chart

    private struct DayData: Identifiable {
        let id = UUID()
        let date: Date
        let exercisesCompleted: Int
    }

    private var chartData: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -(6 - daysAgo), to: today)!
            let dayProgress = user.progress.first { calendar.isDate($0.date, inSameDayAs: date) }
            return DayData(date: date, exercisesCompleted: dayProgress?.exercisesCompleted ?? 0)
        }
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wochenübersicht")
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
            .frame(height: 200)
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
    }
}
