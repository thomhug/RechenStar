# RechenStar - Naechste Schritte

## Stand: 15. Februar 2026

---

## Abgeschlossen

- [x] Phase 1: Engagement-System (Achievements, Streaks, DailyProgress, EngagementService)
- [x] Phase 2: Parent Features Basis (Parent Gate, Pausen-Erinnerung, Basis-Einstellungen)
- [x] Phase 3: Settings, Accessibility, VoiceOver (ThemeManager, Farbpaletten, Dynamic Type)
- [x] Phase 4: Unit Tests (16+ Tests fuer ExerciseGenerator, ExerciseResult, ViewModel, EngagementService)
- [x] Phase 5: Stern-Animation + UI Tests (StarAnimationView, 5 UI Tests)

---

## Phase 6: AchievementsView + Parent Dashboard (AKTUELL)

### 6.1 AchievementsView mit echten Daten
- AchievementsView zeigt aktuell Hardcoded-Beispiele
- SwiftData-Query fuer echte Achievement-Daten des Users
- Fortschrittsbalken pro Achievement (z.B. 7/10 Aufgaben)
- Freigeschaltete vs. gesperrte Achievements visuell unterscheiden

### 6.2 Parent Dashboard mit Statistiken
- Detaillierte Lernstatistiken pro Tag/Woche
- Sessions-Historie
- Accuracy-Trend
- Staerken/Schwaechen-Analyse (Addition vs. Subtraktion)
- Daten aus Session und DailyProgress aggregieren

---

## Phase 7: Polish (Prioritaet NIEDRIG)

### 7.1 Eigene Sound-Dateien
- `SoundService` nutzt nur System-Sounds
- Kindgerechte Sound-Effekte hinzufuegen

### 7.2 Weitere Gamification
- Sticker-System
- Motivations-Sounds bei Streak-Meilensteinen
