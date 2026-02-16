# RechenStar - Naechste Schritte

## Stand: 16. Februar 2026

---

## Abgeschlossen

- [x] Phase 1: Engagement-System (Achievements, Streaks, DailyProgress, EngagementService)
- [x] Phase 2: Parent Features Basis (Parent Gate, Pausen-Erinnerung, Basis-Einstellungen)
- [x] Phase 3: Settings, Accessibility, VoiceOver (ThemeManager, Farbpaletten, Dynamic Type)
- [x] Phase 4: Unit Tests (16+ Tests fuer ExerciseGenerator, ExerciseResult, ViewModel, EngagementService)
- [x] Phase 5: Stern-Animation + UI Tests (StarAnimationView, 5 UI Tests)
- [x] Phase 6: AchievementsView + Parent Dashboard (Fortschritts-Labels, Charts, Staerken/Schwaechen)
- [x] Phase 6.5: Intelligente Aufgabenauswahl (gewichtete Kategorien, schwache Aufgaben wiederholen, ExerciseMetrics)
- [x] Phase 6.6: Revenge-System (Cross-Session Revenge, format-agnostische Erkennung, Revenge-Feedback mit Sterne-Animation)
- [x] Phase 6.7: UX-Verbesserungen
  - timeSpent auf max 10s gekappt
  - Skip zeigt Loesung 2.5s
  - Einstellung: Ueberspringen ausblenden
  - Einstellung: Auto-Loesung nach X Sekunden
  - Level/Skill-Badges antippbar mit Uebersicht-Sheets
  - +/- Verwechslungs-Erkennung mit speziellem Feedback
  - Kompaktes Layout fuer iPhone SE
  - Tagesziel auf HomeView und SessionCompleteView
  - dailyChampion Achievement (100 Aufgaben/Tag)
- [x] Phase 6.8: Bug-Fixes
  - SwiftData UUID-Bug: Relationship-Chain statt Session.id Matching
  - Format-agnostische MetricsService-Gruppierung (Gap-Fill + Standard zaehlen zusammen)
  - Nur korrekte Aufgaben zaehlen fuer totalExercises/Achievements
  - Deterministische Pagination in Aufgaben-Details
  - Uebersprungene Aufgaben aus Metriken und Statistiken ausgeschlossen

---

## Phase 7: Polish (Prioritaet NIEDRIG)

### 7.1 Eigene Sound-Dateien
- `SoundService` nutzt nur System-Sounds
- Kindgerechte Sound-Effekte hinzufuegen

### 7.2 Weitere Gamification
- Sticker-System
- Motivations-Sounds bei Streak-Meilensteinen
