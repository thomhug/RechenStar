import Foundation

struct MetricsService {

    struct RecordData {
        let category: ExerciseCategory
        let exerciseSignature: String
        let firstNumber: Int
        let secondNumber: Int
        let isCorrect: Bool
        let date: Date
    }

    static func computeMetrics(from records: [RecordData]) -> ExerciseMetrics? {
        guard !records.isEmpty else { return nil }

        // Category accuracy
        var categoryGroups: [ExerciseCategory: (correct: Int, total: Int)] = [:]
        for record in records {
            var group = categoryGroups[record.category, default: (correct: 0, total: 0)]
            group.total += 1
            if record.isCorrect { group.correct += 1 }
            categoryGroups[record.category] = group
        }

        var categoryAccuracy: [ExerciseCategory: Double] = [:]
        for (category, group) in categoryGroups {
            categoryAccuracy[category] = Double(group.correct) / Double(group.total)
        }

        // Weak exercises: last attempt was wrong AND overall accuracy < 0.6
        // Group by category + numbers (format-agnostic so standard and gap-fill count together)
        var exerciseGroups: [String: (correct: Int, total: Int, category: ExerciseCategory, first: Int, second: Int, lastDate: Date, lastCorrect: Bool)] = [:]
        for record in records {
            let key = "\(record.category.rawValue)_\(record.firstNumber)_\(record.secondNumber)"
            var group = exerciseGroups[key, default: (correct: 0, total: 0, category: record.category, first: record.firstNumber, second: record.secondNumber, lastDate: .distantPast, lastCorrect: true)]
            group.total += 1
            if record.isCorrect { group.correct += 1 }
            if record.date >= group.lastDate {
                group.lastDate = record.date
                group.lastCorrect = record.isCorrect
            }
            exerciseGroups[key] = group
        }

        var weakExercises: [ExerciseCategory: [(first: Int, second: Int)]] = [:]
        for (_, group) in exerciseGroups {
            let accuracy = Double(group.correct) / Double(group.total)
            // Only weak if last attempt was wrong — after a successful revenge, it drops out
            if accuracy < 0.6 && !group.lastCorrect {
                weakExercises[group.category, default: []].append((first: group.first, second: group.second))
            }
        }

        return ExerciseMetrics(categoryAccuracy: categoryAccuracy, weakExercises: weakExercises)
    }
}
