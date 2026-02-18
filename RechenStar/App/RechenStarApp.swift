import SwiftUI
import SwiftData

@main
struct RechenStarApp: App {
    let modelContainer: ModelContainer
    @State private var appState = AppState()
    @State private var themeManager = ThemeManager()

    init() {
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

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // Store is corrupted — delete and recreate
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let appSupport = urls.first {
                for ext in ["store", "store-shm", "store-wal"] {
                    let url = appSupport.appendingPathComponent("default.\(ext)")
                    try? FileManager.default.removeItem(at: url)
                }
            }
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("Failed to initialize ModelContainer after reset: \(error)")
            }
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
    var fontSize: FontSize = .normal {
        didSet {
            UserDefaults.standard.set(Float(fontSize.rawValue), forKey: "fontSize")
            AppFonts.fontScale = fontSize.rawValue
        }
    }
    var reducedMotion: Bool = false {
        didSet { UserDefaults.standard.set(reducedMotion, forKey: "reducedMotion") }
    }
    var highContrast: Bool = false {
        didSet { UserDefaults.standard.set(highContrast, forKey: "highContrast") }
    }
    var isParentMode = false
    var soundEnabled: Bool = true {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    var hapticEnabled: Bool = true {
        didSet { UserDefaults.standard.set(hapticEnabled, forKey: "hapticEnabled") }
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
        let ud = UserDefaults.standard
        let savedFontSize = ud.float(forKey: "fontSize")
        if savedFontSize > 0, let fs = FontSize(rawValue: CGFloat(savedFontSize)) {
            self.fontSize = fs
        }
        self.reducedMotion = ud.bool(forKey: "reducedMotion")
        self.highContrast = ud.bool(forKey: "highContrast")
        self.soundEnabled = ud.object(forKey: "soundEnabled") == nil ? true : ud.bool(forKey: "soundEnabled")
        self.hapticEnabled = ud.object(forKey: "hapticEnabled") == nil ? true : ud.bool(forKey: "hapticEnabled")
        self.appearanceMode = AppearanceMode(rawValue: ud.string(forKey: "appearanceMode") ?? "system") ?? .system
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
