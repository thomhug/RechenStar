import Foundation

@Observable
final class ExerciseViewModel {

    // MARK: - Enums

    static let maxAttempts = 2

    enum FeedbackState: Equatable {
        case none
        case correct(stars: Int)
        case incorrect
        case showAnswer(Int)
    }

    enum SessionState {
        case notStarted
        case inProgress
        case completed
    }

    // MARK: - State

    private(set) var currentExercise: Exercise?
    var userAnswer: String = ""
    var isNegative: Bool = false
    private(set) var exerciseIndex: Int = 0
    private(set) var sessionResults: [ExerciseResult] = []
    private(set) var feedbackState: FeedbackState = .none
    private(set) var sessionState: SessionState = .notStarted

    let sessionLength: Int
    let categories: [ExerciseCategory]
    let metrics: ExerciseMetrics?
    let adaptiveDifficulty: Bool
    let gapFillEnabled: Bool

    private var exercises: [Exercise] = []
    private var currentAttempts: Int = 0
    private var exerciseStartTime: Date = Date()
    private(set) var currentDifficulty: Difficulty
    private(set) var consecutiveErrors: Int = 0
    private(set) var showEncouragement: Bool = false

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

    var isInputDisabled: Bool {
        if case .showAnswer = feedbackState { return true }
        return feedbackState != .none && feedbackState != .incorrect
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

    var maxDigits: Int {
        3
    }

    var showNegativeToggle: Bool {
        currentExercise?.category == .subtraction_100
    }

    var displayAnswer: String {
        if userAnswer.isEmpty { return "_" }
        return isNegative ? "-\(userAnswer)" : userAnswer
    }

    // MARK: - Init

    init(
        sessionLength: Int = 10,
        difficulty: Difficulty = .easy,
        categories: [ExerciseCategory] = [.addition_10, .subtraction_10],
        metrics: ExerciseMetrics? = nil,
        adaptiveDifficulty: Bool = true,
        gapFillEnabled: Bool = true
    ) {
        self.sessionLength = sessionLength
        self.currentDifficulty = difficulty
        self.categories = categories
        self.metrics = metrics
        self.adaptiveDifficulty = adaptiveDifficulty
        self.gapFillEnabled = gapFillEnabled
    }

    // MARK: - Actions

    func startSession() {
        exercises = ExerciseGenerator.generateSession(
            count: sessionLength,
            difficulty: currentDifficulty,
            categories: categories,
            metrics: metrics,
            allowGapFill: gapFillEnabled
        )
        sessionResults = []
        exerciseIndex = 0
        userAnswer = ""
        isNegative = false
        feedbackState = .none
        currentAttempts = 0
        consecutiveErrors = 0
        showEncouragement = false
        sessionState = .inProgress
        currentExercise = exercises.first
        exerciseStartTime = Date()
    }

    func appendDigit(_ digit: Int) {
        guard feedbackState == .none else { return }
        guard userAnswer.count < maxDigits else { return }
        userAnswer += "\(digit)"
    }

    func deleteLastDigit() {
        guard feedbackState == .none else { return }
        guard !userAnswer.isEmpty else { return }
        userAnswer.removeLast()
    }

    func toggleNegative() {
        guard feedbackState == .none else { return }
        isNegative.toggle()
    }

    func clearShowAnswer() {
        guard case .showAnswer = feedbackState else { return }
        // Move to next exercise after showing the answer
        nextExercise()
    }

    func submitAnswer() {
        guard let exercise = currentExercise,
              let absAnswer = Int(userAnswer),
              feedbackState == .none else { return }

        let answer = isNegative ? -absAnswer : absAnswer
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
            consecutiveErrors = 0
        } else if currentAttempts >= Self.maxAttempts {
            // Show the correct answer after max attempts
            let timeSpent = Date().timeIntervalSince(exerciseStartTime)
            let result = ExerciseResult(
                exercise: exercise,
                userAnswer: answer,
                isCorrect: false,
                attempts: currentAttempts,
                timeSpent: timeSpent,
                wasRevealed: true
            )
            sessionResults.append(result)
            feedbackState = .showAnswer(exercise.correctAnswer)
            consecutiveErrors += 1
        } else {
            feedbackState = .incorrect
        }
    }

    func clearIncorrectFeedback() {
        guard feedbackState == .incorrect else { return }
        feedbackState = .none
        userAnswer = ""
        isNegative = false
    }

    func nextExercise() {
        let nextIndex = exerciseIndex + 1

        if nextIndex >= sessionLength {
            sessionState = .completed
            return
        }

        // Frustration detection: 3+ consecutive errors → reduce difficulty immediately
        if adaptiveDifficulty && consecutiveErrors >= 3 {
            let lowerDifficulty = lowerDifficultyLevel(currentDifficulty)
            if lowerDifficulty != currentDifficulty {
                currentDifficulty = lowerDifficulty
                regenerateRemaining(from: nextIndex)
                showEncouragement = true
            }
            consecutiveErrors = 0
        }
        // Normal adaptive difficulty every 3 exercises
        else if adaptiveDifficulty && nextIndex % 3 == 0 {
            let recentResults = sessionResults.suffix(3)
            let recentAccuracy = Double(recentResults.filter(\.isCorrect).count) / Double(recentResults.count)
            let avgTime = recentResults.map(\.timeSpent).reduce(0, +) / Double(recentResults.count)
            let newDifficulty = ExerciseGenerator.adaptDifficulty(
                current: currentDifficulty,
                recentAccuracy: recentAccuracy,
                averageTime: avgTime
            )
            if newDifficulty != currentDifficulty {
                currentDifficulty = newDifficulty
                regenerateRemaining(from: nextIndex)
            }
        }

        exerciseIndex = nextIndex
        currentExercise = exercises[nextIndex]
        userAnswer = ""
        isNegative = false
        feedbackState = .none
        currentAttempts = 0
        exerciseStartTime = Date()
    }

    func dismissEncouragement() {
        showEncouragement = false
    }

    // MARK: - Private Helpers

    private func regenerateRemaining(from nextIndex: Int) {
        let remaining = sessionLength - nextIndex
        let usedSignatures = Set(exercises.map(\.signature))
        var newExercises: [Exercise] = []
        for _ in 0..<remaining {
            let category = ExerciseGenerator.weightedRandomCategory(from: categories, metrics: metrics)
            let ex = ExerciseGenerator.generate(
                difficulty: currentDifficulty,
                category: category,
                excluding: usedSignatures,
                metrics: metrics,
                allowGapFill: gapFillEnabled
            )
            newExercises.append(ex)
        }
        exercises = Array(exercises.prefix(nextIndex)) + newExercises
    }

    private func lowerDifficultyLevel(_ difficulty: Difficulty) -> Difficulty {
        switch difficulty {
        case .veryEasy: return .veryEasy
        case .easy: return .veryEasy
        case .medium: return .easy
        case .hard: return .medium
        }
    }

    func skipExercise() {
        guard let exercise = currentExercise else { return }

        let timeSpent = Date().timeIntervalSince(exerciseStartTime)
        let result = ExerciseResult(
            exercise: exercise,
            userAnswer: 0,
            isCorrect: false,
            attempts: currentAttempts,
            timeSpent: timeSpent,
            wasSkipped: true
        )
        sessionResults.append(result)
        nextExercise()
    }
}
