# Data Model - RechenStar

## Überblick

Das Datenmodell von RechenStar ist optimiert für lokale Speicherung mit SwiftData und folgt den Prinzipien von Domain-Driven Design.

## Core Models

### Exercise (Aufgabe)

```swift
struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    let type: OperationType      // .addition, .subtraction, .multiplication
    let category: ExerciseCategory
    let firstNumber: Int
    let secondNumber: Int
    let difficulty: Difficulty
    let format: ExerciseFormat   // .standard, .firstGap, .secondGap
    let isRetry: Bool            // Markiert als Revenge-Aufgabe
    let createdAt: Date = Date()

    var correctAnswer: Int { ... }
    var displayText: String { ... }
    var displayNumbers: (left: String, right: String, result: String) { ... }
    var signature: String { ... }  // z.B. "addition_10_3_4_standard" (inkl. Format)
}

enum OperationType: String, Codable, CaseIterable {
    case addition, subtraction, multiplication
    var symbol: String { ... }  // "+", "-", "×"
}

enum ExerciseFormat: String, Codable {
    case standard    // 3 + 4 = ?
    case firstGap    // ? + 4 = 7
    case secondGap   // 3 + ? = 7
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case addition_10        // "Addition bis 10"
    case addition_100       // "Addition bis 100"
    case subtraction_10     // "Subtraktion bis 10"
    case subtraction_100    // "Subtraktion bis 100"
    case multiplication_10  // "Kleines 1x1"
    case multiplication_100 // "Grosses 1x1"

    var type: OperationType { ... }
    var label: String { ... }
    var icon: String { ... }
}

enum Difficulty: Int, Codable, CaseIterable {
    case veryEasy = 1
    case easy = 2
    case medium = 3
    case hard = 4

    var label: String { ... }       // "Sehr leicht" bis "Schwer"
    var skillTitle: String { ... }  // "Entdecker", "Kenner", "Könner", "Meister"
    var skillImageName: String { ... }  // "skill_entdecker" etc.
    var range: ClosedRange<Int> { ... }      // 1...3, 1...5, 2...7, 2...9
    var range100: ClosedRange<Int> { ... }   // 1...20, 1...40, 2...70, 2...99
    var maxProduct: Int { ... }              // 50, 100, 200, 400
}
```

### ExerciseResult (Ergebnis)

```swift
struct ExerciseResult: Identifiable {
    let id: UUID = UUID()
    let exercise: Exercise
    let userAnswer: Int
    let isCorrect: Bool
    let attempts: Int
    let timeSpent: TimeInterval  // Gekappt auf max 10s
    let wasRevealed: Bool        // Auto-Reveal nach Timer
    let wasSkipped: Bool

    var stars: Int {
        guard isCorrect else { return 0 }
        switch attempts {
        case 1: return 2
        default: return 1
        }
    }
}
```

### User (Benutzer)

```swift
@Model
class User {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var avatarCharacter: String = "star"
    var avatarColor: String = "#4A90E2"
    var createdAt: Date = Date()
    var lastActiveAt: Date = Date()

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalExercises: Int = 0   // Nur korrekt gelöste Aufgaben
    var totalStars: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \DailyProgress.user)
    var progress: [DailyProgress] = []

    @Relationship(deleteRule: .cascade, inverse: \Achievement.user)
    var achievements: [Achievement] = []

    @Relationship(deleteRule: .cascade, inverse: \UserPreferences.user)
    var preferences: UserPreferences?

    @Relationship(deleteRule: .cascade, inverse: \AdjustmentLog.user)
    var adjustmentLogs: [AdjustmentLog] = []
}
```

### DailyProgress (Täglicher Fortschritt)

```swift
@Model
class DailyProgress {
    var date: Date
    var exercisesCompleted: Int = 0  // Alle versuchten (nicht übersprungene)
    var correctAnswers: Int = 0
    var totalTime: TimeInterval = 0
    var sessionsCount: Int = 0

    @Relationship(inverse: \User.progress)
    var user: User?

    @Relationship(deleteRule: .cascade)
    var sessions: [Session] = []

    var accuracy: Double {
        guard exercisesCompleted > 0 else { return 0 }
        return Double(correctAnswers) / Double(exercisesCompleted)
    }
}
```

### Session (Übungssitzung)

```swift
@Model
class Session {
    var id: UUID = UUID()
    var startTime: Date = Date()
    var endTime: Date?
    var isCompleted: Bool = false
    var sessionGoal: Int = 10
    var correctCount: Int = 0
    var totalCount: Int = 0
    var starsEarned: Int = 0

    // Pro Rechenart
    var additionTotal: Int = 0
    var additionCorrect: Int = 0
    var subtractionTotal: Int = 0
    var subtractionCorrect: Int = 0

    @Relationship(inverse: \DailyProgress.sessions)
    var dailyProgress: DailyProgress?

    @Relationship(deleteRule: .cascade)
    var exerciseRecords: [ExerciseRecord] = []

    var duration: TimeInterval? { ... }
    var accuracy: Double { ... }
}
```

### ExerciseRecord (Aufgaben-Protokoll)

Persistierte Version eines ExerciseResult fuer Langzeit-Analyse.

```swift
@Model
class ExerciseRecord {
    var id: UUID = UUID()
    var exerciseSignature: String = ""   // z.B. "addition_10_3_4_standard"
    var operationType: String = ""       // "plus", "minus", "mal"
    var category: String = ""            // ExerciseCategory.rawValue
    var firstNumber: Int = 0
    var secondNumber: Int = 0
    var isCorrect: Bool = false
    var timeSpent: TimeInterval = 0
    var attempts: Int = 1
    var wasSkipped: Bool = false
    var difficulty: Int = 2              // Difficulty.rawValue
    var date: Date = Date()

    var session: Session?

    var displayText: String { ... }  // Computed: "3 + 4"
}
```

### Achievement (Erfolge)

```swift
@Model
class Achievement {
    var id: UUID = UUID()
    var typeRawValue: String
    var unlockedAt: Date?
    var progress: Int = 0
    var target: Int

    var type: AchievementType? { ... }
    var isUnlocked: Bool { unlockedAt != nil }
    var progressPercentage: Double { ... }
}

enum AchievementType: String, Codable, CaseIterable {
    // Anzahl-basiert
    case exercises10        // "Erste Schritte" — 10 Aufgaben
    case exercises50        // "Halbes Hundert" — 50 Aufgaben
    case exercises100       // "Hunderter-Held" — 100 Aufgaben
    case exercises500       // "Mathe-Meister" — 500 Aufgaben

    // Streak-basiert
    case streak3            // "3 Tage am Stück"
    case streak7            // "Wochen-Krieger"
    case streak30           // "Monats-Meister"

    // Perfektions-basiert
    case perfect10          // "Perfekte 10" — 10 perfekte Runden (inkrementell)
    case allStars           // "Sterne-Sammler" — 100 Sterne
    case accuracyStreak     // "Treffsicher" — 3 Runden mit 80%+ hintereinander

    // Spezial
    case speedDemon         // "Blitzrechner" — 10 Aufgaben in 2 Min
    case earlyBird          // "Frühaufsteher" — Vor 8 Uhr
    case nightOwl           // "Nachteule" — Nach 20 Uhr
    case categoryMaster     // "Kategorie-Profi" — 90%+ in Kategorie (min 20, kumulativ)
    case variety            // "Vielseitig" — 4+ Kategorien in einer Runde
    case dailyChampion      // "Tages-Champion" — 100 Aufgaben an einem Tag
}
```

### AdjustmentLog (Anpassungs-Protokoll)

```swift
@Model
class AdjustmentLog {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var summary: String = ""

    var user: User?
}
```

### UserPreferences (Einstellungen)

```swift
@Model
class UserPreferences {
    // Gameplay
    var difficultyLevel: Int = 2          // Difficulty.rawValue
    var adaptiveDifficulty: Bool = true
    var sessionLength: Int = 10           // Aufgaben pro Runde
    var dailyGoal: Int = 20              // Tagesziel
    var gapFillEnabled: Bool = true       // Lückenaufgaben (? + 4 = 7)
    var hideSkipButton: Bool = false      // Überspringen-Button ausblenden
    var autoShowAnswerSeconds: Int = 0    // Auto-Lösung (0=aus, 5, 10, 20)

    // Kategorien
    var enabledCategoriesRaw: String = "addition_10,subtraction_10"
    var enabledCategories: [ExerciseCategory] { ... }  // Computed

    // Audio & Haptics
    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var hapticEnabled: Bool = true

    // Visuell / Accessibility
    var reducedMotion: Bool = false
    var highContrast: Bool = false
    var largerText: Bool = false
    var colorBlindMode: ColorBlindMode { ... }  // Computed

    // Eltern-Kontrolle
    var timeLimitMinutes: Int = 0
    var timeLimitEnabled: Bool = false
    var breakReminder: Bool = true
    var breakIntervalSeconds: Int = 900   // 15 Min Standard

    @Relationship(inverse: \User.preferences)
    var user: User?
}
```

## Relationships

```
User (1) ─────> (n) DailyProgress
User (1) ─────> (n) Achievement
User (1) ─────> (1) UserPreferences
User (1) ─────> (n) AdjustmentLog
DailyProgress (1) ─────> (n) Session
Session (1) ─────> (n) ExerciseRecord
```

**Wichtig:** Daten immer über Relationship-Chain traversieren (`user.progress → sessions → exerciseRecords`), nicht über FetchDescriptor + Session.id Matching. SwiftData hat einen Bug bei `UUID = UUID()` Default-Werten — IDs werden beim Laden aus dem Store neu generiert.

## Services

### EngagementService
- Verarbeitet Session-Ergebnisse nach jeder Runde
- Aktualisiert DailyProgress (exercisesCompleted, correctAnswers, totalTime)
- Berechnet Streaks (currentStreak, longestStreak)
- Prüft alle 16 Achievements und schaltet neue frei
- Erkennt Tagesziel-Erreichung

### MetricsService
- Berechnet ExerciseMetrics aus ExerciseRecord-Daten (letzte 30 Tage)
- Kategorie-Genauigkeit pro ExerciseCategory
- Schwache Aufgaben: Genauigkeit < 60% UND letzter Versuch falsch
- **Format-agnostische Gruppierung**: `category_firstNumber_secondNumber` (Standard und Lücken-Formate zählen zusammen)
- Nach erfolgreicher Revenge fällt Aufgabe aus der Weak-Liste

### ExerciseGenerator
- Generiert Aufgaben mit adaptiver Schwierigkeit
- Gewichtete Kategorie-Auswahl basierend auf Performance-Metriken
- 30% Chance schwache Aufgaben (isRetry) einzustreuen
- Duplikat-Vermeidung innerhalb einer Session
- Lückenaufgaben (gap-fill) wenn aktiviert

## Persistence Strategy

### SwiftData Configuration

```swift
@main
struct RechenStarApp: App {
    let modelContainer: ModelContainer

    init() {
        let config = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        modelContainer = try! ModelContainer(
            for: User.self,
                 DailyProgress.self,
                 Session.self,
                 ExerciseRecord.self,
                 Achievement.self,
                 UserPreferences.self,
                 AdjustmentLog.self,
            configurations: config
        )
    }
}
```

## Privacy & Security

- Alle Daten lokal gespeichert
- Keine Cloud-Synchronisation
- Elternbereich direkt zugänglich (kein Passwort, kein Gate)
- Keine persönlichen Daten gesammelt
- Keine Analytics, kein Tracking
