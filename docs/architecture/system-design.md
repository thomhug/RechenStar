# System Design - RechenStar

## Überblick

RechenStar ist eine native iOS-Applikation, entwickelt mit Swift und SwiftUI, die eine MVVM-Architektur mit @Observable implementiert.

## Architektur-Diagramm

```
┌─────────────────────────────────────────────────────────┐
│                     Presentation Layer                  │
│  ┌─────────────────────────────────────────────────┐   │
│  │                SwiftUI Views                     │   │
│  │  ┌──────┐ ┌────────┐ ┌────────┐ ┌──────┐      │   │
│  │  │ Home │ │Exercise │ │Progress│ │Parent│      │   │
│  │  └──────┘ └────────┘ └────────┘ └──────┘      │   │
│  │  ┌────────┐ ┌──────────┐ ┌────────┐           │   │
│  │  │Settings│ │SessionEnd│ │Achievem│           │   │
│  │  └────────┘ └──────────┘ └────────┘           │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │            View Models (@Observable)             │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐       │   │
│  │  │ExerciseVM│ │ AppState │ │ThemeMgr  │       │   │
│  │  └──────────┘ └──────────┘ └──────────┘       │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     Business Layer                      │
│  ┌─────────────────────────────────────────────────┐   │
│  │                   Services                       │   │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐    │   │
│  │  │ Exercise  │ │Engagement │ │  Metrics  │    │   │
│  │  │ Generator │ │ Service   │ │  Service  │    │   │
│  │  └───────────┘ └───────────┘ └───────────┘    │   │
│  │  ┌───────────┐                                 │   │
│  │  │  Sound    │                                 │   │
│  │  │  Service  │                                 │   │
│  │  └───────────┘                                 │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │                Domain Models                     │   │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐  │   │
│  │  │Exercise│ │  User  │ │Session │ │ Record │  │   │
│  │  └────────┘ └────────┘ └────────┘ └────────┘  │   │
│  │  ┌────────┐ ┌────────┐ ┌────────┐             │   │
│  │  │Achievem│ │Progress│ │  Prefs │             │   │
│  │  └────────┘ └────────┘ └────────┘             │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                      Data Layer                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              SwiftData Persistence               │   │
│  │  ┌──────────┐ ┌──────────┐                      │   │
│  │  │Model     │ │UserDefaults│                     │   │
│  │  │Container │ │(Theme)     │                     │   │
│  │  └──────────┘ └──────────┘                      │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    Infrastructure                       │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐           │
│  │  Audio    │ │  Haptic   │ │Animations │           │
│  │  (System) │ │  Feedback │ │(Confetti) │           │
│  └───────────┘ └───────────┘ └───────────┘           │
└─────────────────────────────────────────────────────────┘
```

## Architektur-Prinzipien

### 1. MVVM mit @Observable (iOS 17+)

```swift
// View
struct ExerciseView: View {
    @State private var viewModel: ExerciseViewModel
}

// ViewModel
@Observable
@MainActor
class ExerciseViewModel {
    var exercise: Exercise?
    var feedbackState: FeedbackState = .none
}

// Model
struct Exercise: Identifiable, Codable, Hashable { ... }
```

### 2. Environment-based State

```swift
// App-weiter State via @Observable + @Environment
@Observable class AppState {
    var currentUser: User?
    var selectedTab: ContentTab = .home
}

@Observable class ThemeManager {
    var soundEnabled: Bool  // stored property mit didSet
    var reducedMotion: Bool
}
```

**Wichtig:** `@Observable` computed properties mit UserDefaults loesen kein SwiftUI Re-Rendering aus. Immer stored properties mit `didSet` verwenden.

### 3. Static Services (kein DI)

```swift
// Services sind structs mit static Methoden
struct ExerciseGenerator {
    static func generate(category:difficulty:metrics:) -> Exercise
    static func generateSession(length:categories:difficulty:metrics:) -> [Exercise]
}

struct EngagementService {
    static func processSession(results:session:user:context:) -> EngagementResult
}

struct MetricsService {
    static func computeMetrics(from records: [RecordData]) -> ExerciseMetrics?
}
```

## Komponenten-Details

### Presentation Layer

#### Views (SwiftUI)
- **ExerciseView**: Aufgaben-Anzeige mit NumberPad, Feedback-Animationen, Auto-Advance, Revenge-Sterne, Skip mit Loesungsanzeige, Auto-Reveal Timer
- **HomeView**: Startbildschirm mit Tagesziel, berechnet Metriken ueber Relationship-Chain
- **SessionCompleteView**: Ergebnis-Anzeige mit Konfetti, Achievements, Streak, Tagesziel
- **LearningProgressView**: Level/Skill-Badges (antippbar mit Detail-Sheets), Tages-Stats
- **AchievementsView**: 16 Achievements mit Fortschrittsbalken
- **ParentDashboardView**: Charts, Staerken/Schwaechen, Aufgaben-Details mit Pagination, Fokus-Aufgaben
- **SettingsView**: Gameplay, Kategorien, Accessibility, Eltern-Kontrolle

#### ViewModels
- **ExerciseViewModel**: Session-State, Antwort-Pruefung, adaptive Schwierigkeit, Revenge-Erkennung, +/- Verwechslungs-Erkennung, timeSpent-Cap (10s), autoRevealAnswer

### Business Layer

#### ExerciseGenerator
- Adaptive Schwierigkeit (4 Stufen), Anpassung alle 3 Aufgaben
- 6 Kategorien: Addition/Subtraktion (bis 10, bis 100), Multiplikation (klein, gross)
- 3 Formate: Standard, firstGap, secondGap
- Gewichtete Kategorie-Auswahl (schwache Kategorien bevorzugt)
- 30% Chance schwache Aufgaben einzustreuen (isRetry)
- Duplikat-Vermeidung innerhalb einer Session

#### EngagementService
- Verarbeitet Session-Ergebnisse: DailyProgress, Streaks, 16 Achievements
- Erkennt Tagesziel-Erreichung (dailyGoalReached)
- Inkrementelle Achievement-Pruefung (perfect10, accuracyStreak zaehlen ueber Sessions)

#### MetricsService
- Berechnet ExerciseMetrics aus letzten 30 Tagen
- **Format-agnostische Gruppierung**: Standard und Gap-Fill zaehlen zusammen
- Schwache Aufgaben: Genauigkeit < 60% UND letzter Versuch falsch
- Nach erfolgreicher Revenge faellt Aufgabe aus der Weak-Liste

### Data Layer

#### SwiftData (iOS 17+)
- 6 @Model Klassen: User, DailyProgress, Session, ExerciseRecord, Achievement, UserPreferences
- Cascade-Delete fuer alle User-Beziehungen
- **Wichtig**: Daten immer ueber Relationship-Chain traversieren (SwiftData UUID-Bug)

#### UserDefaults
- ThemeManager-Einstellungen (soundEnabled, reducedMotion, etc.)
- Stored properties mit `didSet` fuer SwiftUI-Kompatibilitaet

## Datenfluss

```
User Input → View → ViewModel → Service → Model → SwiftData
                ↑                                      ↓
                └──────── @Observable Update ←─────────┘
```

### Revenge-Flow (Cross-Session):
```
Session 1: Fehler → ExerciseRecord gespeichert
                         ↓
Session 2 Start: computeMetrics() → MetricsService → weakExercises
                         ↓
ExerciseGenerator: 30% Chance weak exercise als isRetry einzustreuen
                         ↓
Korrekt geloest: .revenge Feedback + Bonus-Sterne
                         ↓
MetricsService: lastCorrect=true → faellt aus Weak-Liste
```

## Feedback-States

```swift
enum FeedbackState {
    case none                                    // Warten auf Eingabe
    case correct(stars: Int)                     // Richtig (1-3 Sterne)
    case revenge(stars: Int)                     // Revenge-Erfolg + Bonus
    case incorrect                               // Falsch (nochmal versuchen)
    case wrongOperation(correct: String, wrong: String)  // +/- Verwechslung
    case showAnswer(Int)                         // Loesung anzeigen (nach 2 Fehlern/Skip/Auto-Reveal)
}
```

## Performance-Optimierungen

- Lazy relationship traversal (nur bei Bedarf)
- ExerciseRecord statt volles ExerciseResult persistieren
- Metriken nur bei Session-Start berechnen (nicht bei jedem Aufgabenwechsel)
- Pagination in Aufgaben-Details (20 pro Seite)

## Testing-Strategie

### Unit Tests (80 Tests)
- `ExerciseGeneratorTests` (33) — Schwierigkeit, Kategorien, Duplikate, schwache Aufgaben
- `ExerciseViewModelTests` (22) — Session-Flow, Revenge, Cross-Session Integration
- `EngagementServiceTests` (12) — Achievements, Streaks, CategoryMaster
- `MetricsServiceTests` (8) — Genauigkeit, Weak Exercises, Format-agnostisch
- `ExerciseResultTests` (5) — Sterne-Berechnung

### UI Tests
- `ExerciseFlowUITests` — Kompletter Session-Flow, Cross-Session Revenge

## Build & Deployment

### Workflow
```bash
# Build-Nummer aktualisieren, bauen, auf alle Geraete deployen
./scripts/build-and-deploy.sh
```

### Deploy-Targets
- iPad von Fritz: `00008020-001079801440402E`
- iPhone von Tom: `00008130-0004446200698D3A`
- iPhone von Anina: `00008110-001858980229401E`

### Xcode-Projekt
- Xcode 15.4 (Build 15F31d)
- objectVersion 56 (nicht 77)
- `xcodebuild build` + `xcrun devicectl device install app`
