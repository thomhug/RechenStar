import Foundation

enum Level: Int, CaseIterable {
    case anfaenger = 1
    case rechenkind = 2
    case zahlenfuchs = 3
    case rechenprofi = 4
    case matheHeld = 5
    case zahlenkoenig = 6
    case rechenstar = 7
    case rechenstar2 = 8
    case rechenstar3 = 9
    case rechenstar4 = 10
    case rechenstar5 = 11

    var title: String {
        switch self {
        case .anfaenger: "Anfänger"
        case .rechenkind: "Rechenkind"
        case .zahlenfuchs: "Zahlenfuchs"
        case .rechenprofi: "Rechenprofi"
        case .matheHeld: "Mathe-Held"
        case .zahlenkoenig: "Zahlenkönig"
        case .rechenstar: "RechenStar"
        case .rechenstar2: "RechenStar 2"
        case .rechenstar3: "RechenStar 3"
        case .rechenstar4: "RechenStar 4"
        case .rechenstar5: "RechenStar 5"
        }
    }

    var requiredExercises: Int {
        switch self {
        case .anfaenger: 0
        case .rechenkind: 25
        case .zahlenfuchs: 75
        case .rechenprofi: 150
        case .matheHeld: 300
        case .zahlenkoenig: 500
        case .rechenstar: 1000
        case .rechenstar2: 2000
        case .rechenstar3: 3000
        case .rechenstar4: 5000
        case .rechenstar5: 10000
        }
    }

    var imageName: String {
        switch self {
        case .anfaenger: "level_anfaenger"
        case .rechenkind: "level_rechenkind"
        case .zahlenfuchs: "level_zahlenfuchs"
        case .rechenprofi: "level_rechenprofi"
        case .matheHeld: "level_mathe_held"
        case .zahlenkoenig: "level_zahlenkoenig"
        case .rechenstar, .rechenstar2, .rechenstar3, .rechenstar4, .rechenstar5: "level_rechenstar"
        }
    }

    /// Next level's required exercises (for progress calculation)
    var nextLevelExercises: Int? {
        guard let nextIndex = Level.allCases.firstIndex(of: self)?.advanced(by: 1),
              nextIndex < Level.allCases.count else { return nil }
        return Level.allCases[nextIndex].requiredExercises
    }

    static func current(for totalExercises: Int) -> Level {
        Level.allCases.last { totalExercises >= $0.requiredExercises } ?? .anfaenger
    }

    static func progress(for totalExercises: Int) -> Double {
        let level = current(for: totalExercises)
        guard let nextRequired = level.nextLevelExercises else { return 1.0 }
        let levelStart = level.requiredExercises
        return Double(totalExercises - levelStart) / Double(nextRequired - levelStart)
    }
}
