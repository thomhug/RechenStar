# Data Model - RechenStar

## Überblick

Das Datenmodell von RechenStar ist optimiert für lokale Speicherung mit SwiftData und folgt den Prinzipien von Domain-Driven Design.

## Core Models

### Exercise (Aufgabe)

```swift
struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    let type: OperationType
    let firstNumber: Int
    let secondNumber: Int
    let difficulty: Difficulty
    let visualHint: VisualHintType?
    let createdAt: Date = Date()

    // Computed Properties
    var correctAnswer: Int {
        switch type {
        case .addition:
            return firstNumber + secondNumber
        case .subtraction:
            return firstNumber - secondNumber
        }
    }

    var displayText: String {
        switch type {
        case .addition:
            return "\(firstNumber) + \(secondNumber) = ?"
        case .subtraction:
            return "\(firstNumber) - \(secondNumber) = ?"
        }
    }
}

enum OperationType: String, Codable, CaseIterable {
    case addition = "plus"
    case subtraction = "minus"

    var symbol: String {
        switch self {
        case .addition: return "+"
        case .subtraction: return "-"
        }
    }
}

enum Difficulty: Int, Codable, CaseIterable {
    case veryEasy = 1  // 1-3
    case easy = 2      // 1-5
    case medium = 3    // 1-7
    case hard = 4      // 1-10

    var range: ClosedRange<Int> {
        switch self {
        case .veryEasy: return 1...3
        case .easy: return 1...5
        case .medium: return 1...7
        case .hard: return 1...10
        }
    }
}
```

### ExerciseResult (Ergebnis)

```swift
struct ExerciseResult: Identifiable, Codable {
    let id: UUID = UUID()
    let exerciseId: UUID
    let exercise: Exercise
    let userAnswer: Int
    let isCorrect: Bool
    let attempts: Int
    let timeSpent: TimeInterval
    let hintsUsed: [HintType]
    let timestamp: Date = Date()

    var stars: Int {
        if !isCorrect { return 0 }
        if attempts == 1 && hintsUsed.isEmpty { return 3 }
        if attempts <= 2 { return 2 }
        return 1
    }
}

enum HintType: String, Codable {
    case visual = "visual"        // Zeige Objekte
    case audio = "audio"          // Vorlesen
    case fingerCount = "finger"   // Finger-Darstellung
    case numberLine = "line"      // Zahlenstrahl
}
```

### User (Benutzer)

```swift
@Model
class User {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var avatar: Avatar
    var createdAt: Date = Date()
    var lastActiveAt: Date = Date()

    @Relationship(deleteRule: .cascade)
    var progress: [DailyProgress] = []

    @Relationship(deleteRule: .cascade)
    var achievements: [Achievement] = []

    @Relationship(deleteRule: .cascade)
    var preferences: UserPreferences?

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalExercises: Int = 0
    var totalStars: Int = 0
}

struct Avatar: Codable {
    let character: CharacterType
    let color: AvatarColor
    let accessories: [Accessory]
}

enum CharacterType: String, Codable, CaseIterable {
    case star = "star"
    case rocket = "rocket"
    case unicorn = "unicorn"
    case robot = "robot"
    case dinosaur = "dinosaur"
}
```

### DailyProgress (Täglicher Fortschritt)

```swift
@Model
class DailyProgress {
    var date: Date
    var exercisesCompleted: Int = 0
    var correctAnswers: Int = 0
    var totalTime: TimeInterval = 0
    var sessionsCount: Int = 0

    @Relationship
    var sessions: [Session] = []

    var accuracy: Double {
        guard exercisesCompleted > 0 else { return 0 }
        return Double(correctAnswers) / Double(exercisesCompleted)
    }

    var averageTimePerExercise: TimeInterval {
        guard exercisesCompleted > 0 else { return 0 }
        return totalTime / Double(exercisesCompleted)
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
    var exercises: [ExerciseResult] = []
    var isCompleted: Bool = false
    var sessionGoal: Int = 10

    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var starsEarned: Int {
        exercises.reduce(0) { $0 + $1.stars }
    }

    var accuracy: Double {
        let correct = exercises.filter { $0.isCorrect }.count
        guard !exercises.isEmpty else { return 0 }
        return Double(correct) / Double(exercises.count)
    }
}
```

### Achievement (Erfolge)

```swift
@Model
class Achievement {
    var id: UUID = UUID()
    var type: AchievementType
    var unlockedAt: Date?
    var progress: Int = 0
    var target: Int

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    var progressPercentage: Double {
        min(Double(progress) / Double(target), 1.0)
    }
}

enum AchievementType: String, Codable, CaseIterable {
    // Anzahl-basiert
    case exercises10 = "first_10"
    case exercises50 = "half_century"
    case exercises100 = "century"
    case exercises500 = "master_500"

    // Streak-basiert
    case streak3 = "streak_3"
    case streak7 = "week_warrior"
    case streak30 = "month_master"

    // Perfektions-basiert
    case perfect10 = "perfect_10"
    case allStars = "star_collector"

    // Spezial
    case speedDemon = "speed_demon"      // 10 in 2 Min
    case earlyBird = "early_bird"        // Vor 8 Uhr
    case nightOwl = "night_owl"          // Nach 20 Uhr

    var title: String {
        // Lokalisierte Titel
    }

    var description: String {
        // Lokalisierte Beschreibungen
    }

    var icon: String {
        // SF Symbol Namen
    }
}
```

### UserPreferences (Einstellungen)

```swift
@Model
class UserPreferences {
    // Gameplay
    var difficulty: Difficulty = .easy
    var adaptiveDifficulty: Bool = true
    var sessionLength: Int = 10
    var dailyGoal: Int = 20

    // Audio & Haptics
    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var hapticEnabled: Bool = true
    var voiceOverEnabled: Bool = false

    // Visual
    var reducedMotion: Bool = false
    var highContrast: Bool = false
    var largerText: Bool = false
    var colorBlindMode: ColorBlindMode = .none

    // Parental
    var parentalPIN: String?
    var timeLimit: TimeInterval?
    var timeLimitEnabled: Bool = false
    var breakReminder: Bool = true
    var breakInterval: TimeInterval = 900 // 15 min
}

enum ColorBlindMode: String, Codable {
    case none = "none"
    case protanopia = "protanopia"
    case deuteranopia = "deuteranopia"
    case tritanopia = "tritanopia"
}
```

### Sticker (Belohnungen)

```swift
struct Sticker: Identifiable, Codable {
    let id: UUID = UUID()
    let category: StickerCategory
    let name: String
    let imageName: String
    let rarity: Rarity
    var isUnlocked: Bool = false
    var unlockedAt: Date?

    enum StickerCategory: String, Codable, CaseIterable {
        case animals = "animals"
        case space = "space"
        case nature = "nature"
        case fantasy = "fantasy"
        case special = "special"
    }

    enum Rarity: Int, Codable, CaseIterable {
        case common = 1
        case uncommon = 2
        case rare = 3
        case epic = 4
        case legendary = 5

        var color: Color {
            switch self {
            case .common: return .gray
            case .uncommon: return .green
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .orange
            }
        }
    }
}
```

## Relationships

```
User (1) ─────> (n) DailyProgress
User (1) ─────> (n) Achievement
User (1) ─────> (1) UserPreferences
DailyProgress (1) ─────> (n) Session
Session (1) ─────> (n) ExerciseResult
ExerciseResult (n) ─────> (1) Exercise
```

## Persistence Strategy

### SwiftData Configuration

```swift
@main
struct RechenStarApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .automatic,
                cloudKitDatabase: .none  // Kein Cloud Sync
            )

            modelContainer = try ModelContainer(
                for: User.self,
                     DailyProgress.self,
                     Session.self,
                     Achievement.self,
                     UserPreferences.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to configure SwiftData")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

### Data Migration

```swift
enum SchemaVersion: Int, CaseIterable {
    case v1 = 1
    case v2 = 2

    var schema: any PersistentModel.Type {
        switch self {
        case .v1: return UserV1.self
        case .v2: return User.self
        }
    }
}

struct MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        SchemaVersion.allCases.map { $0.schema }
    }

    static var stages: [MigrationStage] {
        [MigrationV1toV2()]
    }
}
```

## Data Validation

```swift
extension Exercise {
    func validate() throws {
        guard (1...10).contains(firstNumber) else {
            throw ValidationError.invalidNumber
        }
        guard (1...10).contains(secondNumber) else {
            throw ValidationError.invalidNumber
        }
        if type == .subtraction {
            guard firstNumber >= secondNumber else {
                throw ValidationError.negativeResult
            }
        }
    }
}
```

## Analytics Data (Anonymized)

```swift
struct AnalyticsEvent: Codable {
    let eventType: EventType
    let timestamp: Date
    let properties: [String: Any]

    enum EventType: String {
        case sessionStart
        case sessionComplete
        case exerciseAnswered
        case achievementUnlocked
        case stickerEarned
    }
}
```

## Cache Strategy

```swift
class DataCache {
    private let cache = NSCache<NSString, CacheEntry>()

    func store<T: Codable>(_ object: T, for key: String) {
        // Implementation
    }

    func retrieve<T: Codable>(_ type: T.Type, for key: String) -> T? {
        // Implementation
    }
}
```

## Privacy & Security

- Alle Daten lokal gespeichert
- Keine Cloud-Synchronisation
- Eltern-PIN verschlüsselt im Keychain
- Keine persönlichen Daten gesammelt
- Anonyme Analytics (opt-in)