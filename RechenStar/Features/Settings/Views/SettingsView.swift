import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                InfoCard(
                    title: "Einstellungen",
                    message: "Hier kannst du die App anpassen.",
                    type: .info
                )

                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Schriftgrösse")
                            .font(AppFonts.headline)
                            .foregroundColor(.appTextPrimary)

                        Text("Aktuell: \(themeManager.fontSize.label)")
                            .font(AppFonts.body)
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                AppCard {
                    @Bindable var tm = themeManager
                    Toggle(isOn: $tm.soundEnabled) {
                        HStack(spacing: 8) {
                            Image(systemName: themeManager.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundColor(.appSkyBlue)
                            Text("Töne")
                                .font(AppFonts.headline)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                    .tint(.appSkyBlue)
                }
            }
            .padding(20)

            Text("Version \(Bundle.main.appVersionString)")
                .font(AppFonts.footnote)
                .foregroundColor(.appTextSecondary.opacity(0.5))
                .padding(.bottom, 20)
        }
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
        .environment(ThemeManager())
}
