# System Design - RechenStar

## Überblick

RechenStar ist eine native iOS-Applikation, entwickelt mit Swift und SwiftUI, die eine moderne MVVM-Architektur implementiert.

## Architektur-Diagramm

```
┌─────────────────────────────────────────────────────────┐
│                     Presentation Layer                  │
│  ┌─────────────────────────────────────────────────┐   │
│  │                SwiftUI Views                     │   │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐          │   │
│  │  │ Home │ │Exercise│ │Progress│ │Parent│         │   │
│  │  └──────┘ └──────┘ └──────┘ └──────┘          │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │              View Models (MVVM)                  │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐       │   │
│  │  │ExerciseVM│ │ProgressVM│ │ ParentVM │       │   │
│  │  └──────────┘ └──────────┘ └──────────┘       │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     Business Layer                      │
│  ┌─────────────────────────────────────────────────┐   │
│  │                   Services                       │   │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐    │   │
│  │  │ Exercise  │ │ Progress  │ │Achievement│    │   │
│  │  │ Service   │ │ Tracker   │ │ Manager   │    │   │
│  │  └───────────┘ └───────────┘ └───────────┘    │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │                Domain Models                     │   │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐  │   │
│  │  │Exercise│ │Progress│ │ User   │ │Achievement│ │   │
│  │  └────────┘ └────────┘ └────────┘ └────────┘  │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                      Data Layer                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              SwiftData Persistence               │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐       │   │
│  │  │Model     │ │UserDefaults│ │Keychain │       │   │
│  │  │Container │ │(Settings)  │ │(Secure)  │       │   │
│  │  └──────────┘ └──────────┘ └──────────┘       │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    Infrastructure                       │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐           │
│  │  Audio    │ │  Haptic   │ │ Analytics │           │
│  │  Manager  │ │  Engine   │ │ (Privacy) │           │
│  └───────────┘ └───────────┘ └───────────┘           │
└─────────────────────────────────────────────────────────┘
```

## Architektur-Prinzipien

### 1. MVVM (Model-View-ViewModel)

**Vorteile für RechenStar:**
- Klare Trennung von UI und Business Logic
- Testbarkeit der ViewModels
- SwiftUI-Integration optimal
- Reactive Programming mit Combine

**Implementierung:**
```swift
// View
struct ExerciseView: View {
    @StateObject private var viewModel = ExerciseViewModel()
}

// ViewModel
@MainActor
class ExerciseViewModel: ObservableObject {
    @Published var exercise: Exercise?
    private let exerciseService: ExerciseService
}

// Model
struct Exercise: Identifiable {
    let id: UUID
    // ...
}
```

### 2. Dependency Injection

**Container-based DI:**
```swift
class DIContainer {
    static let shared = DIContainer()

    lazy var exerciseService = ExerciseService()
    lazy var progressTracker = ProgressTracker()
    lazy var audioManager = AudioManager()
}
```

### 3. Protocol-Oriented Programming

```swift
protocol ExerciseProviding {
    func generateExercise() -> Exercise
}

protocol ProgressTracking {
    func recordResult(_ result: ExerciseResult)
}
```

## Komponenten-Details

### Presentation Layer

#### Views (SwiftUI)
- **Atomic Design**: Kleine, wiederverwendbare Komponenten
- **Composition**: Views aus kleineren Views aufbauen
- **State Management**: @State, @StateObject, @EnvironmentObject

#### ViewModels
- **ObservableObject**: Für SwiftUI-Binding
- **@Published**: Für reactive Updates
- **@MainActor**: UI-Thread-Safety

### Business Layer

#### Services
```swift
// ExerciseService.swift
class ExerciseService {
    private let difficultyAdapter = DifficultyAdapter()

    func generateExercise(
        for level: Difficulty
    ) -> Exercise {
        // Adaptive Algorithmus
    }

    func validateAnswer(
        _ answer: Int,
        for exercise: Exercise
    ) -> ExerciseResult {
        // Validation Logic
    }
}
```

#### Domain Models
- **Value Types**: Structs für Immutability
- **Codable**: Für Serialization
- **Identifiable**: Für SwiftUI Lists

### Data Layer

#### SwiftData (iOS 17+)
```swift
@Model
class ProgressData {
    var date: Date
    var exercisesCompleted: Int
    var correctAnswers: Int
    var achievements: [Achievement]
}
```

#### UserDefaults
- App-Einstellungen
- User-Präferenzen
- Nicht-sensitive Daten

#### Keychain
- Eltern-PIN
- Sensitive Settings
- Token (falls benötigt)

## Datenfluss

```
User Input → View → ViewModel → Service → Model → Persistence
                ↑                                      ↓
                └──────── State Update ←──────────────┘
```

## Threading-Strategie

```swift
// Main Thread: UI Updates
@MainActor
class SomeViewModel: ObservableObject {
    // UI-related code
}

// Background: Heavy Operations
Task {
    await processData()
    await MainActor.run {
        updateUI()
    }
}
```

## Error Handling

```swift
enum AppError: LocalizedError {
    case networkError
    case dataCorruption
    case unknownError

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Netzwerkfehler"
        // ...
        }
    }
}
```

## Performance-Optimierungen

### Memory Management
- Weak References für Delegate-Pattern
- Lazy Loading für große Datensets
- Image Caching mit NSCache

### UI Performance
- List mit LazyVStack
- Drawing Group für komplexe Animationen
- Async Image Loading

## Security & Privacy

### Daten-Sicherheit
- Lokale Speicherung only
- Keine Cloud-Sync
- Verschlüsselte Sensitive Daten

### Privacy by Design
- Keine Tracking-Libraries
- Minimale Datensammlung
- Transparente Datenschutzerklärung

## Testing-Strategie

### Unit Tests
```swift
class ExerciseServiceTests: XCTestCase {
    func testExerciseGeneration() {
        // Test implementation
    }
}
```

### UI Tests
```swift
class ExerciseFlowUITests: XCTestCase {
    func testCompleteExerciseSession() {
        // UI test flow
    }
}
```

### Integration Tests
- Service-Integration
- Data Persistence
- State Management

## Build & Deployment

### Environments
```swift
enum Environment {
    case development
    case staging
    case production

    var baseURL: String {
        // Return appropriate URL
    }
}
```

### CI/CD Pipeline
1. Code Commit → GitHub
2. GitHub Actions → Build & Test
3. TestFlight → Beta Testing
4. App Store → Production

## Monitoring & Analytics

### Privacy-First Analytics
- Nur aggregierte Daten
- Keine User-Identifikation
- Opt-in only

### Crash Reporting
- Symbolicated Crash Logs
- Automatic Bug Tracking
- Performance Monitoring

## Skalierbarkeit

### Horizontal
- Feature Modules
- Lazy Loading
- Code Splitting

### Vertical
- Service Layer Abstraction
- Database Migration Support
- API Versioning (future)