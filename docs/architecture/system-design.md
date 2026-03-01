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
    var isParentMode = false
    var currentSession: Session?
    var hasLaunchedBefore: Bool  // UserDefaults-backed
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
- **ExerciseViewModel**: Session-State, Antwort-Pruefung, adaptive Schwierigkeit (alle 2 Aufgaben + Frustrations-Erkennung), Revenge-Erkennung, +/- Verwechslungs-Erkennung, timeSpent-Cap (10s), autoRevealAnswer

### Business Layer

#### ExerciseGenerator
- Adaptive Schwierigkeit (4 Stufen), Anpassung alle 2 Aufgaben
- 6 Kategorien: Addition/Subtraktion (bis 10, bis 100), Multiplikation (klein, gross)
- 3 Formate: Standard, firstGap, secondGap
- Gewichtete Kategorie-Auswahl (schwache Kategorien bevorzugt)
- 30% Chance schwache Aufgaben einzustreuen (isRetry)
- Duplikat-Vermeidung innerhalb einer Session
- Hard-Mode Multiplikation: Faktoren 10 und 20 ausgeschlossen (trivial einfach)

##### Adaptiver Schwierigkeits-Algorithmus

Paedagogische Grundlage: **Errorless Learning** (Fehler koennen sich bei Kindern als falsche Antworten einpraegen) und **Selbstwirksamkeit** (Erfolg baut Vertrauen auf). Daher: lieber zu leicht als zu schwer. Hochstufen nur bei fehlerfreiem, automatisiertem Wissen.

**1. Start-Schwierigkeit** (bei Session-Beginn, basierend auf den letzten 30 Tagen):

| Ø Genauigkeit | Start-Stufe |
|---|---|
| ≥ 90% | Schwer |
| ≥ 70% | Mittel |
| ≥ 50% | Leicht |
| < 50% | Sehr leicht |

Bei manueller Schwierigkeit (nicht "Automatisch") wird die gewaehlte Stufe direkt verwendet.

**2. Laufende Anpassung** (alle 2 Aufgaben innerhalb einer Session):

| Richtig (2 Aufgaben) | Ø Loese-Zeit | Aktion |
|---|---|---|
| 2/2 | < 3s | 1 Stufe hoch (automatisiert) |
| 2/2 | ≥ 3s | Bleibt (kann es, aber noch nicht schnell genug) |
| 1/2 | egal | Bleibt |
| 0/2 | egal | 1 Stufe runter |
| egal | > 7s | 1 Stufe runter (ueberfordert, auch bei richtiger Antwort) |

Prinzipien:
- **Kein Turbo-Sprung**: Maximal 1 Stufe pro Anpassung (vermeidet ploetzliche Ueberforderung)
- **Hoch nur bei 0 Fehlern UND schnell**: Ein Fehler bedeutet, die Stufe ist noch nicht gemeistert
- **Zeit als eigenes Signal**: Langsames Loesen (>7s) zeigt Ueberforderung, auch bei richtiger Antwort
- **Schneller runter als hoch**: Frustration ist schaedlicher als Langeweile bei diesem Alter (6-10)

Bei Stufenwechsel werden die verbleibenden Aufgaben der Session neu generiert.

**3. Frustrations-Erkennung** (bei jedem 2er-Check):

Letzte 4 Aufgaben < 40% Genauigkeit (≤ 1 richtig) → 1 Stufe runter + Ermutigungs-Nachricht. Erkennt auch nicht-aufeinanderfolgende Fehler (z.B. Falsch-Richtig-Falsch-Falsch).

**4. Zahlenbereich pro Stufe:**

| Stufe | Addition/Subtraktion bis 10 | bis 100 | Kleines 1×1 | Grosses 1×1 (max. Produkt) |
|---|---|---|---|---|
| Sehr leicht | 1–3 | 1–20 | 2–3 | 50, ab 2×2 |
| Leicht | 1–5 | 1–40 | 2–5 | 100, ab 2×2 |
| Mittel | 2–7 | 2–70 | 2–7 | 200, ab 2×2 |
| Schwer | 2–9 | 2–99 | 2–9 | 400, ab 2×2 |

Multiplikation verwendet immer Minimum-Faktor 2 (1×n ist trivial). Bei Schwer-Multiplikation (grosses 1×1) werden die Faktoren 10 und 20 ausgeschlossen (trivial einfach).

**5. Zeitschwellen (paedagogisch begruendet):**

| Loese-Zeit | Bedeutung |
|---|---|
| < 3s | Automatisiertes Wissen (sofort gewusst) |
| 3–5s | Entwickelt sich, kurz ueberlegt |
| 5–7s | Muss rechnen, an der Grenze |
| > 7s | Ueberfordert (zaehlt an Fingern, nutzt Umwege) |

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
    case correct(stars: Int)                     // Richtig (1-2 Sterne)
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

### Unit Tests (93 Tests)
- `ExerciseGeneratorTests` (41) — Schwierigkeit, Kategorien, Duplikate, schwache Aufgaben, Zeit-Schwellen, Multiplikations-Minimum, Addition-Bounds
- `ExerciseViewModelTests` (28) — Session-Flow, Revenge, Cross-Session Integration, Frustrations-Erkennung, Auto-Reveal
- `EngagementServiceTests` (12) — Achievements, Streaks, CategoryMaster
- `MetricsServiceTests` (8) — Genauigkeit, Weak Exercises, Format-agnostisch
- `ExerciseResultTests` (4) — Sterne-Berechnung

### UI Tests (11 Tests)
- `ExerciseFlowUITests` (9) — Kompletter Session-Flow, Cross-Session Revenge, NumberPad, Skip, Cancel
- `NavigationUITests` (1) — Tab-Navigation
- `ScreenshotUITests` (1) — App Store Screenshots

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
