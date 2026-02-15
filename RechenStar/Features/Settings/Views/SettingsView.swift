import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    private var prefs: UserPreferences? {
        appState.currentUser?.preferences
    }

    var body: some View {
        @Bindable var tm = themeManager

        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Gameplay
                VStack(alignment: .leading, spacing: 16) {
                    Label("Spieleinstellungen", systemImage: "gamecontroller.fill")
                        .font(AppFonts.headline)
                        .foregroundColor(.appTextPrimary)

                    if let prefs {
                        HStack {
                            Text("Aufgaben pro Runde")
                                .font(AppFonts.body)
                                .foregroundColor(.appTextPrimary)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { prefs.sessionLength },
                                set: { prefs.sessionLength = $0; save() }
                            )) {
                                Text("5").tag(5)
                                Text("10").tag(10)
                                Text("15").tag(15)
                                Text("20").tag(20)
                            }
                            .pickerStyle(.menu)
                        }

                        HStack {
                            Text("Schwierigkeit")
                                .font(AppFonts.body)
                                .foregroundColor(.appTextPrimary)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { prefs.adaptiveDifficulty ? 0 : prefs.difficultyLevel },
                                set: { newValue in
                                    if newValue == 0 {
                                        prefs.adaptiveDifficulty = true
                                    } else {
                                        prefs.adaptiveDifficulty = false
                                        prefs.difficultyLevel = newValue
                                    }
                                    save()
                                }
                            )) {
                                Text("Automatisch").tag(0)
                                Text("Leicht").tag(1)
                                Text("Mittel").tag(2)
                                Text("Schwer").tag(3)
                            }
                            .pickerStyle(.menu)
                        }

                        HStack {
                            Text("Tägliches Ziel")
                                .font(AppFonts.body)
                                .foregroundColor(.appTextPrimary)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { prefs.dailyGoal },
                                set: { prefs.dailyGoal = $0; save() }
                            )) {
                                Text("10 Aufgaben").tag(10)
                                Text("20 Aufgaben").tag(20)
                                Text("30 Aufgaben").tag(30)
                                Text("50 Aufgaben").tag(50)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .settingsCard()

                // MARK: - Audio
                VStack(alignment: .leading, spacing: 16) {
                    Label("Ton & Haptik", systemImage: "speaker.wave.2.fill")
                        .font(AppFonts.headline)
                        .foregroundColor(.appTextPrimary)

                    Toggle(isOn: $tm.soundEnabled) {
                        HStack(spacing: 8) {
                            Image(systemName: themeManager.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundColor(.appSkyBlue)
                                .frame(width: 24)
                            Text("Töne")
                                .font(AppFonts.body)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                    .tint(.appSkyBlue)

                    Toggle(isOn: $tm.hapticEnabled) {
                        HStack(spacing: 8) {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundColor(.appSkyBlue)
                                .frame(width: 24)
                            Text("Vibration")
                                .font(AppFonts.body)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                    .tint(.appSkyBlue)
                }
                .settingsCard()

                // MARK: - Display
                VStack(alignment: .leading, spacing: 16) {
                    Label("Darstellung", systemImage: "eye.fill")
                        .font(AppFonts.headline)
                        .foregroundColor(.appTextPrimary)

                    HStack {
                        Text("Schriftgrösse")
                            .font(AppFonts.body)
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        Picker("", selection: $tm.fontSize) {
                            ForEach(ThemeManager.FontSize.allCases, id: \.self) { size in
                                Text(size.label).tag(size)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Toggle(isOn: $tm.reducedMotion) {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.walk.motion")
                                .foregroundColor(.appSkyBlue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Weniger Animationen")
                                    .font(AppFonts.body)
                                    .foregroundColor(.appTextPrimary)
                                Text("Reduziert Konfetti, Wackeln und Übergänge")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                    }
                    .tint(.appSkyBlue)

                    Toggle(isOn: $tm.highContrast) {
                        HStack(spacing: 8) {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundColor(.appSkyBlue)
                                .frame(width: 24)
                            Text("Hoher Kontrast")
                                .font(AppFonts.body)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                    .tint(.appSkyBlue)
                }
                .settingsCard()

                // MARK: - Version
                Text("Version \(Bundle.main.appVersionString)")
                    .font(AppFonts.footnote)
                    .foregroundColor(.appTextSecondary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(20)
        }
    }

    private func save() {
        try? modelContext.save()
    }
}

// MARK: - Settings Card Modifier
private extension View {
    func settingsCard() -> some View {
        self
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appCardBackground)
            )
    }
}

extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(ThemeManager())
}
