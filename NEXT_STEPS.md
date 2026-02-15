# RechenStar - Konkrete Nächste Schritte

## 🎯 Sofort startbereit für nächste Session

### SCHRITT 1: Xcode-Projekt erstellen (5 Min)

```bash
# Terminal-Befehle:
cd /Users/tom/Documents/code/RechenStar
open .  # Öffnet Finder im Projektordner
```

**In Xcode:**
1. File → New → Project
2. iOS → App → Next
3. Einstellungen:
   - Product Name: `RechenStar`
   - Team: (Dein Team)
   - Organization Identifier: `com.yourname.rechenstar`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Use Core Data: `NO` (wir nutzen SwiftData)
   - Include Tests: `YES`

### SCHRITT 2: Vorhandene Dateien integrieren (5 Min)

**Kopiere diese Ordner ins Xcode-Projekt:**
```
RechenStar/App/ → Xcode RechenStar/App/
RechenStar/Design/ → Xcode RechenStar/Design/
```

**In Xcode:**
1. Lösche die automatisch generierte ContentView.swift
2. Drag & Drop unsere Dateien ins Projekt
3. Build (⌘B) um Fehler zu checken

### SCHRITT 3: Fehlende Models implementieren (20 Min)

#### A. Exercise Model erstellen

**Neue Datei:** `RechenStar/Core/Models/Exercise.swift`

```swift
import Foundation
import SwiftData

// Operation Types
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

// Difficulty Levels
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

// Exercise Model
struct Exercise: Identifiable, Codable, Hashable {
    let id = UUID()
    let type: OperationType
    let firstNumber: Int
    let secondNumber: Int
    let difficulty: Difficulty
    let createdAt = Date()

    var correctAnswer: Int {
        switch type {
        case .addition:
            return firstNumber + secondNumber
        case .subtraction:
            return firstNumber - secondNumber
        }
    }

    var displayText: String {
        "\(firstNumber) \(type.symbol) \(secondNumber) = ?"
    }
}

// Exercise Result
struct ExerciseResult: Identifiable, Codable {
    let id = UUID()
    let exerciseId: UUID
    let userAnswer: Int
    let isCorrect: Bool
    let attempts: Int
    let timeSpent: TimeInterval
    let timestamp = Date()

    var stars: Int {
        if !isCorrect { return 0 }
        if attempts == 1 { return 3 }
        if attempts <= 2 { return 2 }
        return 1
    }
}
```

#### B. User Model erstellen

**Neue Datei:** `RechenStar/Core/Models/User.swift`

```swift
import Foundation
import SwiftData

@Model
final class User {
    var id = UUID()
    var name: String = "Spieler"
    var avatarName: String = "star"
    var createdAt = Date()
    var lastActiveAt = Date()

    // Statistics
    var totalExercises: Int = 0
    var totalCorrect: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalStars: Int = 0

    // Relationships
    @Relationship(deleteRule: .cascade)
    var sessions: [Session] = []

    @Relationship(deleteRule: .cascade)
    var achievements: [Achievement] = []

    init(name: String = "Spieler") {
        self.name = name
    }
}
```

#### C. Session Model erstellen

**Neue Datei:** `RechenStar/Core/Models/Session.swift`

```swift
import Foundation
import SwiftData

@Model
final class Session {
    var id = UUID()
    var startTime = Date()
    var endTime: Date?
    var exerciseResults: [ExerciseResult] = []
    var isCompleted: Bool = false
    var targetExercises: Int = 10

    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var correctCount: Int {
        exerciseResults.filter { $0.isCorrect }.count
    }

    var accuracy: Double {
        guard !exerciseResults.isEmpty else { return 0 }
        return Double(correctCount) / Double(exerciseResults.count)
    }

    var totalStars: Int {
        exerciseResults.reduce(0) { $0 + $1.stars }
    }

    init() {}
}
```

### SCHRITT 4: ExerciseGenerator Service (15 Min)

**Neue Datei:** `RechenStar/Core/Services/ExerciseGenerator.swift`

```swift
import Foundation

class ExerciseGenerator: ObservableObject {
    @Published var currentDifficulty: Difficulty = .easy
    private var recentExercises: [Exercise] = []
    private let maxHistory = 10

    func generateExercise(
        type: OperationType? = nil,
        difficulty: Difficulty? = nil
    ) -> Exercise {
        let selectedType = type ?? OperationType.allCases.randomElement()!
        let selectedDifficulty = difficulty ?? currentDifficulty

        var exercise: Exercise
        repeat {
            exercise = createExercise(
                type: selectedType,
                difficulty: selectedDifficulty
            )
        } while isRepeat(exercise)

        // Track recent exercises
        recentExercises.append(exercise)
        if recentExercises.count > maxHistory {
            recentExercises.removeFirst()
        }

        return exercise
    }

    private func createExercise(
        type: OperationType,
        difficulty: Difficulty
    ) -> Exercise {
        let range = difficulty.range

        switch type {
        case .addition:
            let first = Int.random(in: range)
            let maxSecond = min(10 - first, range.upperBound)
            let second = Int.random(in: 1...max(1, maxSecond))
            return Exercise(
                type: type,
                firstNumber: first,
                secondNumber: second,
                difficulty: difficulty
            )

        case .subtraction:
            let first = Int.random(in: range)
            let second = Int.random(in: 1...first)
            return Exercise(
                type: type,
                firstNumber: first,
                secondNumber: second,
                difficulty: difficulty
            )
        }
    }

    private func isRepeat(_ exercise: Exercise) -> Bool {
        recentExercises.contains { existing in
            existing.firstNumber == exercise.firstNumber &&
            existing.secondNumber == exercise.secondNumber &&
            existing.type == exercise.type
        }
    }

    func adjustDifficulty(basedOn results: [ExerciseResult]) {
        guard results.count >= 5 else { return }

        let recentResults = results.suffix(5)
        let accuracy = Double(recentResults.filter { $0.isCorrect }.count) / 5.0

        if accuracy >= 0.9 && currentDifficulty != .hard {
            // Increase difficulty
            if let nextLevel = Difficulty(rawValue: currentDifficulty.rawValue + 1) {
                currentDifficulty = nextLevel
            }
        } else if accuracy < 0.5 && currentDifficulty != .veryEasy {
            // Decrease difficulty
            if let prevLevel = Difficulty(rawValue: currentDifficulty.rawValue - 1) {
                currentDifficulty = prevLevel
            }
        }
    }
}
```

### SCHRITT 5: Basis Exercise View (20 Min)

**Neue Datei:** `RechenStar/Features/Exercise/Views/ExerciseView.swift`

```swift
import SwiftUI

struct ExerciseView: View {
    @StateObject private var viewModel = ExerciseViewModel()
    @State private var userInput = ""
    @State private var showFeedback = false

    var body: some View {
        VStack(spacing: 30) {
            // Progress Bar
            ProgressBar(
                current: viewModel.currentExerciseIndex,
                total: viewModel.totalExercises
            )
            .padding(.horizontal)

            // Exercise Display
            if let exercise = viewModel.currentExercise {
                ExerciseCard(
                    firstNumber: exercise.firstNumber,
                    secondNumber: exercise.secondNumber,
                    operation: exercise.type.symbol,
                    showResult: false,
                    result: nil
                )
            }

            // User Input Display
            Text(userInput.isEmpty ? "?" : userInput)
                .font(AppFonts.numberHuge)
                .foregroundColor(.appSkyBlue)
                .frame(minHeight: 80)

            // Number Pad
            NumberPadView(userInput: $userInput)

            // Buttons
            HStack(spacing: 20) {
                Button("Löschen") {
                    userInput = ""
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("Prüfen") {
                    checkAnswer()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(userInput.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .overlay(
            FeedbackOverlay(
                isShowing: $showFeedback,
                isCorrect: viewModel.lastAnswerCorrect,
                stars: viewModel.lastStarsEarned
            )
        )
        .onAppear {
            viewModel.startNewSession()
        }
    }

    private func checkAnswer() {
        guard let answer = Int(userInput) else { return }

        viewModel.submitAnswer(answer)
        showFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showFeedback = false
            userInput = ""
            viewModel.nextExercise()
        }
    }
}

// Simple Number Pad View
struct NumberPadView: View {
    @Binding var userInput: String

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(0...20, id: \.self) { number in
                NumberPadButton(number: number) { num in
                    userInput = "\(num)"
                }
            }
        }
        .padding()
    }
}

// Progress Bar
struct ProgressBar: View {
    let current: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appSkyBlue)
                    .frame(width: geometry.size.width * progress, height: 20)
                    .animation(.spring(), value: progress)
            }
        }
        .frame(height: 20)
    }
}
```

### SCHRITT 6: Exercise ViewModel

**Neue Datei:** `RechenStar/Features/Exercise/ViewModels/ExerciseViewModel.swift`

```swift
import Foundation
import SwiftUI

@MainActor
class ExerciseViewModel: ObservableObject {
    @Published var currentExercise: Exercise?
    @Published var currentExerciseIndex = 0
    @Published var lastAnswerCorrect = false
    @Published var lastStarsEarned = 0
    @Published var sessionResults: [ExerciseResult] = []

    let totalExercises = 10
    private let generator = ExerciseGenerator()
    private var currentSession: Session?
    private var attempts = 0
    private var exerciseStartTime = Date()

    func startNewSession() {
        currentSession = Session()
        sessionResults = []
        currentExerciseIndex = 0
        nextExercise()
    }

    func nextExercise() {
        guard currentExerciseIndex < totalExercises else {
            completeSession()
            return
        }

        currentExercise = generator.generateExercise()
        attempts = 0
        exerciseStartTime = Date()
        currentExerciseIndex += 1
    }

    func submitAnswer(_ answer: Int) {
        guard let exercise = currentExercise else { return }

        attempts += 1
        let isCorrect = answer == exercise.correctAnswer
        let timeSpent = Date().timeIntervalSince(exerciseStartTime)

        let result = ExerciseResult(
            exerciseId: exercise.id,
            userAnswer: answer,
            isCorrect: isCorrect,
            attempts: attempts,
            timeSpent: timeSpent
        )

        sessionResults.append(result)
        lastAnswerCorrect = isCorrect
        lastStarsEarned = result.stars

        // Adjust difficulty if needed
        generator.adjustDifficulty(basedOn: sessionResults)
    }

    private func completeSession() {
        currentSession?.exerciseResults = sessionResults
        currentSession?.endTime = Date()
        currentSession?.isCompleted = true

        // Save session to database
        // TODO: Implement persistence
    }
}
```

## 📋 CHECKLISTE FÜR NÄCHSTE SESSION

### Sofort-Tasks (1-2 Stunden):
- [ ] Xcode-Projekt erstellen
- [ ] Vorhandene Dateien integrieren
- [ ] Models implementieren (Exercise, User, Session)
- [ ] ExerciseGenerator Service
- [ ] Basis ExerciseView
- [ ] ExerciseViewModel
- [ ] Test: Erste Mathe-Aufgabe lösen!

### Danach (2-3 Stunden):
- [ ] FeedbackOverlay mit Sternen
- [ ] Sound-Integration
- [ ] Haptic Feedback
- [ ] Session-Completion Screen
- [ ] Home View mit Play-Button

### Testing:
- [ ] 10 Aufgaben durchspielen
- [ ] Schwierigkeitsanpassung testen
- [ ] UI auf iPhone SE testen
- [ ] VoiceOver kurz prüfen

## 🔧 DEBUGGING-HILFEN

### Häufige Fehler:

1. **SwiftData Crash:**
   ```swift
   // Stelle sicher, dass ModelContainer richtig initialisiert ist
   // in RechenStarApp.swift
   ```

2. **View Updates nicht sichtbar:**
   ```swift
   // Verwende @Published und @StateObject
   // Checke MainActor für ViewModels
   ```

3. **Number Pad reagiert nicht:**
   ```swift
   // Checke Binding von userInput
   // Haptic Feedback einbauen zum Debuggen
   ```

## 💡 TIPPS

1. **Erst funktionsfähig, dann schön** - UI-Polish kommt später
2. **Dummy-Daten verwenden** - Für schnelles Testing
3. **Print-Statements** - Für schnelles Debugging
4. **Git-Commits** - Nach jedem funktionierenden Feature

## 🎯 ERFOLGSKRITERIEN FÜR NÄCHSTE SESSION

✅ Eine Mathe-Aufgabe wird angezeigt
✅ Zahlen-Eingabe funktioniert
✅ Antwort-Check gibt Feedback
✅ Nächste Aufgabe wird geladen
✅ 10 Aufgaben durchspielbar

---

**Viel Erfolg! Die Grundlagen sind solide - jetzt geht's ans Implementieren! 🚀**