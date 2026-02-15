import Foundation

@Observable
final class ExerciseViewModel {

    // MARK: - Enums

    enum FeedbackState: Equatable {
        case none
        case correct(stars: Int)
        case incorrect
    }

    enum SessionState {
        case notStarted
        case inProgress
        case completed
    }

    // MARK: - State

    private(set) var currentExercise: Exercise?
    var userAnswer: String = ""
    private(set) var exerciseIndex: Int = 0
    private(set) var sessionResults: [ExerciseResult] = []
    private(set) var feedbackState: FeedbackState = .none
    private(set) var sessionState: SessionState = .notStarted

    let sessionLength: Int

    private var exercises: [Exercise] = []
    private var currentAttempts: Int = 0
    private var exerciseStartTime: Date = Date()
    private var currentDifficulty: Difficulty

    // MARK: - Computed

    var progressText: String {
        "\(exerciseIndex + 1) von \(sessionLength)"
    }

    var progressFraction: Double {
        Double(exerciseIndex) / Double(sessionLength)
    }

    var canSubmit: Bool {
        !userAnswer.isEmpty && feedbackState == .none
    }

    var totalStars: Int {
        sessionResults.reduce(0) { $0 + $1.stars }
    }

    var correctCount: Int {
        sessionResults.filter(\.isCorrect).count
    }

    var accuracy: Double {
        guard !sessionResults.isEmpty else { return 0 }
        return Double(correctCount) / Double(sessionResults.count)
    }

    // MARK: - Init

    init(sessionLength: Int = 10, difficulty: Difficulty = .easy) {
        self.sessionLength = sessionLength
        self.currentDifficulty = difficulty
    }

    // MARK: - Actions

    func startSession() {
        exercises = ExerciseGenerator.generateSession(
            count: sessionLength,
            difficulty: currentDifficulty
        )
        sessionResults = []
        exerciseIndex = 0
        userAnswer = ""
        feedbackState = .none
        currentAttempts = 0
        sessionState = .inProgress
        currentExercise = exercises.first
        exerciseStartTime = Date()
    }

    func appendDigit(_ digit: Int) {
        guard feedbackState == .none else { return }
        guard userAnswer.count < 2 else { return }
        userAnswer += "\(digit)"
    }

    func deleteLastDigit() {
        guard feedbackState == .none else { return }
        guard !userAnswer.isEmpty else { return }
        userAnswer.removeLast()
    }

    func submitAnswer() {
        guard let exercise = currentExercise,
              let answer = Int(userAnswer),
              feedbackState == .none else { return }

        currentAttempts += 1

        if answer == exercise.correctAnswer {
            let timeSpent = Date().timeIntervalSince(exerciseStartTime)
            let result = ExerciseResult(
                exercise: exercise,
                userAnswer: answer,
                isCorrect: true,
                attempts: currentAttempts,
                timeSpent: timeSpent
            )
            sessionResults.append(result)
            feedbackState = .correct(stars: result.stars)
        } else {
            feedbackState = .incorrect
        }
    }

    func clearIncorrectFeedback() {
        guard feedbackState == .incorrect else { return }
        feedbackState = .none
        userAnswer = ""
    }

    func nextExercise() {
        let nextIndex = exerciseIndex + 1

        if nextIndex >= sessionLength {
            sessionState = .completed
            return
        }

        // Adaptive difficulty every 3 exercises
        if nextIndex % 3 == 0 {
            let recentResults = sessionResults.suffix(3)
            let recentAccuracy = Double(recentResults.filter(\.isCorrect).count) / Double(recentResults.count)
            let newDifficulty = ExerciseGenerator.adaptDifficulty(
                current: currentDifficulty,
                recentAccuracy: recentAccuracy
            )
            if newDifficulty != currentDifficulty {
                currentDifficulty = newDifficulty
                // Regenerate remaining exercises at new difficulty
                let remaining = sessionLength - nextIndex
                let usedSignatures = Set(exercises.map(\.signature))
                var newExercises: [Exercise] = []
                for _ in 0..<remaining {
                    let ex = ExerciseGenerator.generate(
                        difficulty: currentDifficulty,
                        excluding: usedSignatures
                    )
                    newExercises.append(ex)
                }
                exercises = Array(exercises.prefix(nextIndex)) + newExercises
            }
        }

        exerciseIndex = nextIndex
        currentExercise = exercises[nextIndex]
        userAnswer = ""
        feedbackState = .none
        currentAttempts = 0
        exerciseStartTime = Date()
    }

    func skipExercise() {
        guard let exercise = currentExercise else { return }

        let timeSpent = Date().timeIntervalSince(exerciseStartTime)
        let result = ExerciseResult(
            exercise: exercise,
            userAnswer: 0,
            isCorrect: false,
            attempts: currentAttempts,
            timeSpent: timeSpent
        )
        sessionResults.append(result)
        nextExercise()
    }
}
