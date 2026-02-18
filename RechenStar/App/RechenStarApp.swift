import SwiftUI
import SwiftData
import SQLite3

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

        // 1. Try normal open
        if let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) {
            modelContainer = container
            Self.createBackup()
        }
        // 2. Repair: checkpoint WAL and retry
        else if Self.repairStore(), let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) {
            modelContainer = container
            Self.createBackup()
        }
        // 3. Restore from backup
        else if Self.restoreFromBackup(), let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) {
            modelContainer = container
        }
        // 4. Last resort: delete and recreate (data lost)
        else {
            Self.deleteStore()
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

    private static var storeURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("default.store")
    }

    /// Repair corrupted store by checkpointing the WAL via sqlite3
    @discardableResult
    private static func repairStore() -> Bool {
        guard let url = storeURL else { return false }
        let path = url.path

        var db: OpaquePointer?
        guard sqlite3_open(path, &db) == SQLITE_OK else { return false }
        defer { sqlite3_close(db) }

        // Checkpoint WAL — merges WAL into main store file
        var pnLog: Int32 = 0
        var pnCkpt: Int32 = 0
        let rc = sqlite3_wal_checkpoint_v2(db, nil, SQLITE_CHECKPOINT_TRUNCATE, &pnLog, &pnCkpt)

        return rc == SQLITE_OK
    }

    // MARK: - Backup

    private static var backupDir: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("Backups")
    }

    /// Create a backup of the current store (keep last 3)
    private static func createBackup() {
        guard let storeURL, let backupDir else { return }
        let fm = FileManager.default

        // Only backup if store exists and has data
        guard fm.fileExists(atPath: storeURL.path),
              (try? fm.attributesOfItem(atPath: storeURL.path)[.size] as? UInt64) ?? 0 > 0 else { return }

        // Checkpoint WAL first so backup is self-contained
        repairStore()

        try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let backupName = "backup-\(formatter.string(from: Date())).store"
        let destination = backupDir.appendingPathComponent(backupName)

        try? fm.copyItem(at: storeURL, to: destination)

        // Keep only last 3 backups
        if let files = try? fm.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: [.creationDateKey])
            .filter({ $0.pathExtension == "store" })
            .sorted(by: { ($0.lastPathComponent) > ($1.lastPathComponent) }) {
            for file in files.dropFirst(3) {
                try? fm.removeItem(at: file)
            }
        }
    }

    /// Try to restore from most recent backup
    private static func restoreFromBackup() -> Bool {
        guard let backupDir else { return false }
        let fm = FileManager.default

        guard let backups = try? fm.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension == "store" })
            .sorted(by: { $0.lastPathComponent > $1.lastPathComponent }) else { return false }

        for backup in backups {
            // Delete current corrupt store
            deleteStore()

            guard let storeURL else { return false }
            if (try? fm.copyItem(at: backup, to: storeURL)) != nil {
                return true
            }
        }
        return false
    }

    /// Delete all store files as last resort
    private static func deleteStore() {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        for ext in ["store", "store-shm", "store-wal"] {
            try? FileManager.default.removeItem(at: appSupport.appendingPathComponent("default.\(ext)"))
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
