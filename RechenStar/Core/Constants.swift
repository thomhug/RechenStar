import Foundation

/// Zentrale Konstanten für das Aufgaben- und Schwierigkeitssystem.
/// Pädagogische Begründung: siehe docs/architecture/system-design.md
enum ExerciseConstants {

    // MARK: - Adaptive Schwierigkeit

    /// Lösezeit unter der automatisiertes Wissen angenommen wird (Sekunden)
    static let fastTimeThreshold: TimeInterval = 3.0

    /// Lösezeit über der das Kind überfordert ist — auch bei richtiger Antwort (Sekunden)
    static let slowTimeThreshold: TimeInterval = 7.0

    /// Anzahl Aufgaben zwischen Schwierigkeits-Anpassungen
    static let adaptationCheckInterval = 2

    /// Grösse des rollierenden Fensters für Frustrations-Erkennung
    static let frustrationWindowSize = 4

    /// Genauigkeit unter der im Frustrations-Fenster eine Stufe gesenkt wird
    static let frustrationAccuracyThreshold = 0.4

    // MARK: - Start-Schwierigkeit (basierend auf Ø Genauigkeit der letzten 30 Tage)

    /// Ab dieser Genauigkeit: Start auf Schwer
    static let startHardThreshold = 0.9

    /// Ab dieser Genauigkeit: Start auf Mittel
    static let startMediumThreshold = 0.7

    /// Ab dieser Genauigkeit: Start auf Leicht
    static let startEasyThreshold = 0.5

    // MARK: - Aufgaben-Generierung

    /// Wahrscheinlichkeit, eine schwache Aufgabe einzustreuen (wenn vorhanden)
    static let weakExerciseChance = 0.3

    /// Wahrscheinlichkeit für Lückenaufgaben (bei berechtigten Kategorien)
    static let gapFillChance = 0.3

    /// Minimum-Faktor bei Multiplikation (1×n ist trivial)
    static let minimumMultiplicationFactor = 2

    /// Faktoren, die bei Schwer-Multiplikation (grosses 1×1) ausgeschlossen werden
    static let excludedHardMultiplicationFactors: Set<Int> = [10, 20]

    // MARK: - Session

    /// Maximale aufgezeichnete Zeit pro Aufgabe (Sekunden). Verhindert AFK-Verzerrung.
    static let timeSpentCap: TimeInterval = 10.0

    /// Maximale Fehlversuche bevor die Lösung angezeigt wird
    static let maxAttempts = 2
}
