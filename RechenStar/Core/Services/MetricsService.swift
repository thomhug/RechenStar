import Foundation

struct MetricsService {

    struct RecordData {
        let category: ExerciseCategory
        let exerciseSignature: String
        let firstNumber: Int
        let secondNumber: Int
        let isCorrect: Bool
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

        // Weak exercises: accuracy < 0.6 with at least 2 attempts
        var signatureGroups: [String: (correct: Int, total: Int, category: ExerciseCategory, first: Int, second: Int)] = [:]
        for record in records {
            let sig = record.exerciseSignature
            var group = signatureGroups[sig, default: (correct: 0, total: 0, category: record.category, first: record.firstNumber, second: record.secondNumber)]
            group.total += 1
            if record.isCorrect { group.correct += 1 }
            signatureGroups[sig] = group
        }

        var weakExercises: [ExerciseCategory: [(first: Int, second: Int)]] = [:]
        for (_, group) in signatureGroups {
            let accuracy = Double(group.correct) / Double(group.total)
            if accuracy < 0.6 {
                weakExercises[group.category, default: []].append((first: group.first, second: group.second))
            }
        }

        return ExerciseMetrics(categoryAccuracy: categoryAccuracy, weakExercises: weakExercises)
    }
}
