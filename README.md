# RechenStar

Eine kindgerechte Mathe-Lern-App für iOS, speziell entwickelt für Grundschulkinder (6-10 Jahre).

## Projektziel

RechenStar macht Mathematik-Lernen zum Spass! Die App hilft Kindern, Addition, Subtraktion und Multiplikation spielerisch zu meistern.

## Hauptmerkmale

### Für Kinder:
- **6 Aufgabentypen**: Addition und Subtraktion (bis 10 und bis 100), kleines und grosses Einmaleins
- **3 Aufgabenformate**: Standard (3 + 4 = ?), Lückenaufgaben (? + 4 = 7, 3 + ? = 7)
- **Positive Verstärkung**: Sterne, 16 Erfolge und Konfetti-Animationen
- **Kindgerechtes Design**: Grosse Buttons, klare Farben, kompaktes Layout für kleine Geräte
- **Adaptive Schwierigkeit**: Passt sich dem Lerntempo an (4 Stufen)
- **Intelligente Aufgabenauswahl**: Schwache Kategorien und Aufgaben werden gezielt wiederholt
- **Revenge-System**: Falsch gelöste Aufgaben kommen wieder — bei Erfolg gibt es Bonus-Sterne
- **+/- Verwechslungs-Erkennung**: Hinweis wenn Plus statt Minus gerechnet wird (oder umgekehrt)
- **Keine Frustration**: Immer ermutigendes Feedback, Lösung wird nach 2 Fehlversuchen gezeigt

### Für Eltern:
- **Fortschrittsverfolgung**: Detaillierte Statistiken pro Aufgabentyp
- **Stärken & Schwächen**: Genauigkeit pro Kategorie auf einen Blick, fliesst in Aufgabenauswahl ein
- **Aufgaben-Details**: Einzelne Aufgaben mit Zeiten und Erfolgsquote
- **Fokus-Aufgaben**: Automatisch erkannte Schwachstellen
- **Zeitkontrolle**: Einstellbare Session-Längen und Pausen-Erinnerung
- **Einstellungen**: Kategorien, Schwierigkeit, Lückenaufgaben, Skip-Button, Auto-Lösung-Timer
- **100% Sicher**: Keine Werbung, keine In-App-Käufe
- **Datenschutz**: DSGVO-konform, lokale Datenspeicherung

## Aufgabentypen

| Kategorie | Zahlenbereich | Besonderheit |
|-----------|---------------|-------------|
| Addition bis 10 | Summe max. 10 | Einstieg |
| Addition bis 100 | Summe max. 100 | Zweistellig |
| Subtraktion bis 10 | Ergebnis >= 0 | Einstieg |
| Subtraktion bis 100 | Negativ erlaubt | Mit +/- Button |
| Kleines 1x1 | Faktoren 1-10 | Einmaleins |
| Grosses 1x1 | Produkt max. 100 | Fortgeschritten |

## Technologie-Stack

- **Platform**: iOS 17+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM mit @Observable
- **Persistence**: SwiftData
- **Min. Target**: iPhone SE, iPad

## Projektstruktur

```
RechenStar/
├── RechenStar/
│   ├── App/           # App Entry Point, ContentView
│   ├── Core/
│   │   ├── Models/    # Exercise, ExerciseCategory, User, Session, ExerciseRecord
│   │   └── Services/  # ExerciseGenerator, MetricsService, EngagementService
│   ├── Features/
│   │   ├── Home/      # Startbildschirm
│   │   ├── Exercise/  # Aufgaben-View und ViewModel
│   │   ├── Session/   # Session-Abschluss
│   │   ├── Progress/  # Fortschritt und Erfolge
│   │   ├── Settings/  # Einstellungen und Hilfe
│   │   └── Parent/    # Eltern-Dashboard
│   ├── Design/        # Theme, Fonts, Components, Animations
│   └── Resources/     # Assets & Sounds
├── RechenStarTests/    # 80 Unit Tests
├── RechenStarUITests/  # UI Tests
└── scripts/            # Build & Deploy
```

## Setup & Installation

### Voraussetzungen:
- Xcode 15.4+
- iOS 17.0+ Simulator oder Gerät
- macOS Sonoma oder neuer

### Installation:
```bash
git clone https://github.com/thomhug/RechenStar.git
cd RechenStar
open RechenStar.xcodeproj
# Build & Run (Cmd+R)
```

## Barrierefreiheit

RechenStar ist für ALLE Kinder:
- VoiceOver Support
- Dynamic Type / einstellbare Schriftgrösse
- Erscheinungsbild (Hell/Dunkel/System)
- Reduzierte Bewegung (weniger Animationen)
- Farbenblind-Modi (Protanopie, Deuteranopie, Tritanopie)

## Lizenz

Copyright 2026 anbeda AG. Alle Rechte vorbehalten.

## Kontakt

anbeda AG — rechenstar@tom.li
