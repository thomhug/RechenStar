import SwiftUI
import SwiftData

@main
struct RechenStarApp: App {
    let modelContainer: ModelContainer
    @State private var appState = AppState()
    @State private var themeManager = ThemeManager()

    init() {
        do {
            let schema = Schema([
                User.self,
                DailyProgress.self,
                Session.self,
                Achievement.self,
                UserPreferences.self,
                ExerciseRecord.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }

        UserDefaults.standard.register(defaults: [
            "soundEnabled": true,
            "hapticEnabled": true,
        ])
        AppFonts.fontScale = themeManager.fontSize.rawValue
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(themeManager)
                .environment(\.colorTheme, themeManager.currentTheme)
                .preferredColorScheme(themeManager.preferredColorScheme)
                .modelContainer(modelContainer)
        }
    }

    private func configureAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.rounded(ofSize: 34, weight: .bold)
        ]
    }
}

// MARK: - App State
@Observable
final class AppState {
    var currentUser: User?
    var isParentMode = false
    var currentSession: Session?
    var hasLaunchedBefore: Bool {
        get { UserDefaults.standard.bool(forKey: "hasLaunchedBefore") }
        set { UserDefaults.standard.set(newValue, forKey: "hasLaunchedBefore") }
    }

    func startNewSession() {
        currentSession = Session()
    }

    func endSession() {
        currentSession?.endTime = Date()
        currentSession?.isCompleted = true
        currentSession = nil
    }
}

// MARK: - Theme Manager
@Observable
final class ThemeManager {
    var fontSize: FontSize {
        get { FontSize(rawValue: CGFloat(UserDefaults.standard.float(forKey: "fontSize"))) ?? .normal }
        set {
            UserDefaults.standard.set(Float(newValue.rawValue), forKey: "fontSize")
            AppFonts.fontScale = newValue.rawValue
        }
    }
    var reducedMotion: Bool {
        get { UserDefaults.standard.bool(forKey: "reducedMotion") }
        set { UserDefaults.standard.set(newValue, forKey: "reducedMotion") }
    }
    var highContrast: Bool {
        get { UserDefaults.standard.bool(forKey: "highContrast") }
        set { UserDefaults.standard.set(newValue, forKey: "highContrast") }
    }
    var isParentMode = false
    var soundEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "soundEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "soundEnabled") }
    }
    var hapticEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "hapticEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "hapticEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "hapticEnabled") }
    }

    var appearanceMode: AppearanceMode = .system {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode") }
    }

    var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        self.appearanceMode = AppearanceMode(rawValue: saved) ?? .system
    }

    var currentTheme: ColorTheme {
        highContrast ? DarkColorTheme() : DefaultColorTheme()
    }

    enum AppearanceMode: String, CaseIterable {
        case system
        case light
        case dark

        var label: String {
            switch self {
            case .system: "Automatisch"
            case .light: "Hell"
            case .dark: "Dunkel"
            }
        }
    }

    enum FontSize: CGFloat, CaseIterable {
        case small = 0.8
        case normal = 1.0
        case large = 1.2
        case extraLarge = 1.5

        var label: String {
            switch self {
            case .small: "Klein"
            case .normal: "Normal"
            case .large: "Gross"
            case .extraLarge: "Sehr gross"
            }
        }
    }
}
