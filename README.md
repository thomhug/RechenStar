# RechenStar

Eine kindgerechte Mathe-Lern-App für iOS, speziell entwickelt für Grundschulkinder (6-10 Jahre).

## Projektziel

RechenStar macht Mathematik-Lernen zum Spass! Die App hilft Kindern, Addition, Subtraktion und Multiplikation spielerisch zu meistern.

## Hauptmerkmale

### Für Kinder:
- **6 Aufgabentypen**: Addition und Subtraktion (bis 10 und bis 100), kleines und grosses Einmaleins
- **Positive Verstärkung**: Sterne, Erfolge und Konfetti-Animationen
- **Kindgerechtes Design**: Grosse Buttons, klare Farben
- **Adaptive Schwierigkeit**: Passt sich dem Lerntempo an
- **Keine Frustration**: Immer ermutigendes Feedback

### Für Eltern:
- **Fortschrittsverfolgung**: Detaillierte Statistiken pro Aufgabentyp
- **Stärken & Schwächen**: Genauigkeit pro Kategorie auf einen Blick
- **Aufgaben-Details**: Einzelne Aufgaben mit Zeiten und Erfolgsquote
- **Zeitkontrolle**: Einstellbare Session-Längen und Pausen-Erinnerung
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
│   │   ├── Models/    # Exercise, ExerciseCategory, User, Session
│   │   └── Services/  # ExerciseGenerator, EngagementService
│   ├── Features/
│   │   ├── Home/      # Startbildschirm
│   │   ├── Exercise/  # Aufgaben-View und ViewModel
│   │   ├── Settings/  # Einstellungen und Hilfe
│   │   ├── Parent/    # Eltern-Dashboard
│   │   ├── Progress/  # Fortschritt und Erfolge
│   │   └── Session/   # Session-Abschluss
│   ├── Design/        # Theme, Fonts, Components
│   └── Resources/     # Assets & Sounds
├── RechenStarTests/    # Unit Tests
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

## Lizenz

Copyright 2026 anbeda AG. Alle Rechte vorbehalten.

## Kontakt

anbeda AG — rechenstar@tom.li
