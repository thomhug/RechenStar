import Foundation
import SwiftData

@Model
final class UserPreferences {
    // Gameplay
    var difficultyLevel: Int = 2
    var adaptiveDifficulty: Bool = true
    var sessionLength: Int = 10
    var dailyGoal: Int = 20

    // Audio & Haptics
    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var hapticEnabled: Bool = true

    // Visual
    var reducedMotion: Bool = false
    var highContrast: Bool = false
    var largerText: Bool = false
    var colorBlindModeRawValue: String = ColorBlindMode.none.rawValue

    // Categories
    var enabledCategoriesRaw: String = "addition_10,subtraction_10"

    // Parental
    var timeLimitMinutes: Int = 0
    var timeLimitEnabled: Bool = false
    var breakReminder: Bool = true
    var breakIntervalSeconds: Int = 900

    var user: User?

    var colorBlindMode: ColorBlindMode {
        get { ColorBlindMode(rawValue: colorBlindModeRawValue) ?? .none }
        set { colorBlindModeRawValue = newValue.rawValue }
    }

    var enabledCategories: [ExerciseCategory] {
        get {
            enabledCategoriesRaw
                .split(separator: ",")
                .compactMap { ExerciseCategory(rawValue: String($0)) }
        }
        set {
            enabledCategoriesRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    init() {}
}

enum ColorBlindMode: String, Codable, CaseIterable {
    case none = "none"
    case protanopia = "protanopia"
    case deuteranopia = "deuteranopia"
    case tritanopia = "tritanopia"

    var label: String {
        switch self {
        case .none: "Keine"
        case .protanopia: "Protanopie (Rot-Blind)"
        case .deuteranopia: "Deuteranopie (Grün-Blind)"
        case .tritanopia: "Tritanopie (Blau-Blind)"
        }
    }
}
