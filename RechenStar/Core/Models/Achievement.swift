import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID = UUID()
    var typeRawValue: String = ""
    var unlockedAt: Date?
    var progress: Int = 0
    var target: Int = 1

    var user: User?

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    var progressPercentage: Double {
        min(Double(progress) / Double(max(target, 1)), 1.0)
    }

    var type: AchievementType? {
        AchievementType(rawValue: typeRawValue)
    }

    init(type: AchievementType, target: Int) {
        self.typeRawValue = type.rawValue
        self.target = target
    }
}

enum AchievementType: String, Codable, CaseIterable {
    case exercises10 = "first_10"
    case exercises50 = "half_century"
    case exercises100 = "century"
    case exercises500 = "master_500"

    case streak3 = "streak_3"
    case streak7 = "week_warrior"
    case streak30 = "month_master"

    case perfect10 = "perfect_10"
    case allStars = "star_collector"

    case speedDemon = "speed_demon"
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"

    var title: String {
        switch self {
        case .exercises10: "Erste Schritte"
        case .exercises50: "Halbes Hundert"
        case .exercises100: "Hunderter-Held"
        case .exercises500: "Mathe-Meister"
        case .streak3: "3 Tage am Stück"
        case .streak7: "Wochen-Krieger"
        case .streak30: "Monats-Meister"
        case .perfect10: "Perfekte 10"
        case .allStars: "Sterne-Sammler"
        case .speedDemon: "Blitzrechner"
        case .earlyBird: "Frühaufsteher"
        case .nightOwl: "Nachteule"
        }
    }

    var description: String {
        switch self {
        case .exercises10: "Löse 10 Aufgaben"
        case .exercises50: "Löse 50 Aufgaben"
        case .exercises100: "Löse 100 Aufgaben"
        case .exercises500: "Löse 500 Aufgaben"
        case .streak3: "Übe 3 Tage hintereinander"
        case .streak7: "Übe 7 Tage hintereinander"
        case .streak30: "Übe 30 Tage hintereinander"
        case .perfect10: "10 Aufgaben ohne Fehler"
        case .allStars: "Sammle 100 Sterne"
        case .speedDemon: "10 Aufgaben in 2 Minuten"
        case .earlyBird: "Übe vor 8 Uhr morgens"
        case .nightOwl: "Übe nach 20 Uhr abends"
        }
    }

    var icon: String {
        switch self {
        case .exercises10: "10.circle.fill"
        case .exercises50: "50.circle.fill"
        case .exercises100: "medal.fill"
        case .exercises500: "trophy.fill"
        case .streak3: "flame.fill"
        case .streak7: "flame.fill"
        case .streak30: "flame.fill"
        case .perfect10: "star.circle.fill"
        case .allStars: "star.fill"
        case .speedDemon: "bolt.fill"
        case .earlyBird: "sunrise.fill"
        case .nightOwl: "moon.stars.fill"
        }
    }

    var defaultTarget: Int {
        switch self {
        case .exercises10: 10
        case .exercises50: 50
        case .exercises100: 100
        case .exercises500: 500
        case .streak3: 3
        case .streak7: 7
        case .streak30: 30
        case .perfect10: 10
        case .allStars: 100
        case .speedDemon: 1
        case .earlyBird: 1
        case .nightOwl: 1
        }
    }
}
