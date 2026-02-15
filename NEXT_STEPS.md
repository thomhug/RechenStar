# RechenStar - Naechste Schritte

## Stand: 15. Februar 2026

---

## Phase 1: Engagement-System (Prioritaet HOCH)

Das Grundgeruest fuer Aufgaben und Sessions funktioniert. Jetzt muessen die Engagement-Features mit Leben gefuellt werden, damit die App Kinder motiviert.

### 1.1 Achievement-Berechnung nach jeder Session
- Achievement-Typen sind in `Achievement.swift` definiert (12 Typen)
- Logik fehlt: nach `HomeView.saveSession()` pruefen, ob neue Achievements freigeschaltet werden
- Beispiel: `exercises10` freischalten wenn `user.totalExercises >= 10`

### 1.2 Streak-Update
- `User`-Model hat `currentStreak` und `longestStreak`
- In `HomeView.saveSession()` muss geprueft werden, ob heute schon gespielt wurde
- Wenn ja: Streak beibehalten. Wenn nein: Streak erhoehen oder zuruecksetzen

### 1.3 DailyProgress-Aggregation
- `DailyProgress`-Model existiert, wird aber nirgends befuellt
- Nach jeder Session: heutigen DailyProgress finden oder erstellen, Werte aktualisieren

### 1.4 Stern-/Konfetti-Animation
- Sterne werden berechnet aber nicht animiert
- Stern-Sammel-Animation nach korrekter Antwort
- Konfetti-Animation auf SessionCompleteView

---

## Phase 2: Parent Features (Prioritaet MITTEL)

### 2.1 Parent Gate mit echter Validierung
- Aktuell: Stub in `ContentView.swift` mit Mathe-Aufgabe
- Erweitern: Richtige Validierung der Antwort, Zugang nur bei korrekter Loesung

### 2.2 Parent Dashboard mit Statistiken
- Neue View: Detaillierte Lernstatistiken pro Tag/Woche
- Sessions-Historie, Accuracy-Trend, Staerken/Schwaechen-Analyse
- Daten aus `Session` und `DailyProgress` aggregieren

### 2.3 Zeitlimit-Enforcement
- `UserPreferences` hat `timeLimitMinutes` und `breakReminderEnabled`
- Fehlend: Timer der die Spielzeit ueberwacht und bei Erreichen des Limits stoppt
- Sanfte Erinnerung: "Zeit fuer eine Pause!" statt harter Sperre

---

## Phase 3: Polish (Prioritaet MITTEL)

### 3.1 Accessibility-Settings anwenden
- `UserPreferences` definiert: reducedMotion, highContrast, largerText, colorBlindMode
- Settings-UI erweitern damit Nutzer diese Optionen aendern koennen
- Alle Views muessen die Settings tatsaechlich respektieren

### 3.2 Mehr Sounds und Animationen
- `SoundService` nutzt nur System-Sounds — eigene Sound-Dateien hinzufuegen
- Uebergangs-Animationen zwischen Aufgaben
- Motivations-Sounds bei Streak-Meilensteinen

### 3.3 VoiceOver-Labels vervollstaendigen
- Basis-Labels vorhanden, aber nicht flaechendeckend
- Alle interaktiven Elemente mit accessibilityLabel und accessibilityHint versehen
- Exercise-Aufgaben als gesprochenen Text bereitstellen

---

## Phase 4: Testing (Prioritaet NIEDRIG)

### 4.1 Unit Tests
- ExerciseGenerator: Korrekte Zahlenraenge, keine negativen Ergebnisse, Duplikat-Vermeidung
- ExerciseResult: Sterne-Berechnung
- Difficulty-Anpassung: Hoch-/Runterstufen bei guter/schlechter Accuracy

### 4.2 UI Tests
- Exercise-Flow: 10 Aufgaben durchspielen, Session-Complete erreichen
- NumberPad-Eingabe, Antwort pruefen, Feedback-Anzeige
- Navigation zwischen Tabs

---

## Offene TODOs (nach Prioritaet)

### Hoch
- [ ] Achievement-Unlocking-Logik nach Session-Ende
- [ ] Streak-Berechnung in saveSession()
- [ ] DailyProgress befuellen
- [ ] AchievementsView mit echten Daten statt Hardcoded-Beispielen

### Mittel
- [ ] Parent Gate validieren
- [ ] Parent Dashboard erstellen
- [ ] Zeitlimit-Timer implementieren
- [ ] SettingsView erweitern (alle UserPreferences editierbar)
- [ ] Stern-Animation bei korrekter Antwort
- [ ] Konfetti auf SessionCompleteView

### Niedrig
- [ ] Eigene Sound-Dateien statt System-Sounds
- [ ] VoiceOver-Labels vervollstaendigen
- [ ] Accessibility-Settings in allen Views anwenden
- [ ] Unit Tests fuer ExerciseGenerator
- [ ] UI Tests fuer Exercise-Flow
