import SwiftUI
import SwiftData
import SQLite3

private enum RecoveryState {
    case loading
    case ready(ModelContainer)
    case needsBackupRestore(backupDate: String)
    case needsFullReset
}

@main
struct RechenStarApp: App {
    @State private var recoveryState: RecoveryState = .loading
    @State private var appState = AppState()
    @State private var themeManager = ThemeManager()

    init() {
        _recoveryState = State(initialValue: Self.attemptInitialization())

        UserDefaults.standard.register(defaults: [
            "soundEnabled": true,
            "hapticEnabled": true,
        ])
        AppFonts.fontScale = themeManager.fontSize.rawValue
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            switch recoveryState {
            case .loading:
                ProgressView("Laden...")
            case .ready(let container):
                ContentView()
                    .environment(appState)
                    .environment(themeManager)
                    .environment(\.colorTheme, themeManager.currentTheme)
                    .preferredColorScheme(themeManager.preferredColorScheme)
                    .modelContainer(container)
            case .needsBackupRestore(let backupDate):
                RecoveryView(
                    message: "Die Datenbank ist beschädigt. Letztes Backup vom \(backupDate) wiederherstellen?",
                    primaryButtonLabel: "Wiederherstellen",
                    isDestructive: false,
                    primaryAction: {
                        if Self.restoreFromBackup(), let container = Self.makeContainer() {
                            recoveryState = .ready(container)
                        } else {
                            recoveryState = .needsFullReset
                        }
                    }
                )
            case .needsFullReset:
                RecoveryView(
                    message: "Die Datenbank kann nicht repariert werden. Alle Daten müssen gelöscht werden, um die App weiter zu nutzen.",
                    primaryButtonLabel: "Alle Daten löschen",
                    isDestructive: true,
                    primaryAction: {
                        Self.deleteStore()
                        if let container = Self.makeContainer() {
                            recoveryState = .ready(container)
                        }
                    }
                )
            }
        }
    }

    private static var storeURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("default.store")
    }

    private static func makeContainer() -> ModelContainer? {
        let schema = Schema([
            User.self,
            DailyProgress.self,
            Session.self,
            Achievement.self,
            UserPreferences.self,
            ExerciseRecord.self,
            AdjustmentLog.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, allowsSave: true)
        return try? ModelContainer(for: schema, configurations: [config])
    }

    private static func attemptInitialization() -> RecoveryState {
        // 1. Normal open
        if let container = makeContainer() {
            createBackup()
            return .ready(container)
        }

        // 2. WAL repair + retry
        if repairStore(), let container = makeContainer() {
            createBackup()
            return .ready(container)
        }

        // 3-4. Need user input — check if backups exist
        if let backupDate = getMostRecentBackupDate() {
            return .needsBackupRestore(backupDate: backupDate)
        }
        return .needsFullReset
    }

    private static func getMostRecentBackupDate() -> String? {
        guard let backupDir else { return nil }
        let fm = FileManager.default
        guard let backups = try? fm.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension == "store" })
            .sorted(by: { $0.lastPathComponent > $1.lastPathComponent }),
            let mostRecent = backups.first else { return nil }

        let name = mostRecent.deletingPathExtension().lastPathComponent
        guard name.hasPrefix("backup-") else { return nil }
        let dateStr = String(name.dropFirst("backup-".count))

        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd_HHmmss"
        guard let date = parser.date(from: dateStr) else { return nil }

        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        display.locale = Locale(identifier: "de_DE")
        return display.string(from: date)
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
        #if !targetEnvironment(macCatalyst)
        if !ProcessInfo.processInfo.isiOSAppOnMac {
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: UIFont.rounded(ofSize: 34, weight: .bold)
            ]
        }
        #endif
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

// MARK: - Recovery View
private struct RecoveryView: View {
    let message: String
    let primaryButtonLabel: String
    let isDestructive: Bool
    let primaryAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text("Datenbankfehler")
                .font(.title2.bold())

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button(action: primaryAction) {
                Text(primaryButtonLabel)
                    .frame(maxWidth: 260)
            }
            .buttonStyle(.borderedProminent)
            .tint(isDestructive ? .red : .accentColor)
            .controlSize(.large)

            Button("App beenden") {
                exit(0)
            }
            .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
