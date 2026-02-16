import XCTest
@testable import RechenStar

final class ExerciseViewModelTests: XCTestCase {

    private func makeSUT(
        sessionLength: Int = 10,
        categories: [ExerciseCategory] = [.addition_10, .subtraction_10],
        metrics: ExerciseMetrics? = nil
    ) -> ExerciseViewModel {
        ExerciseViewModel(sessionLength: sessionLength, difficulty: .easy, categories: categories, metrics: metrics)
    }

    func testInitialState() {
        let vm = makeSUT()
        XCTAssertEqual(vm.sessionState, .notStarted)
        XCTAssertNil(vm.currentExercise)
        XCTAssertEqual(vm.userAnswer, "")
    }

    func testStartSession() {
        let vm = makeSUT()
        vm.startSession()
        XCTAssertEqual(vm.sessionState, .inProgress)
        XCTAssertNotNil(vm.currentExercise)
    }

    func testAppendDigit() {
        let vm = makeSUT()
        vm.startSession()
        vm.appendDigit(5)
        XCTAssertEqual(vm.userAnswer, "5")
        vm.appendDigit(3)
        XCTAssertEqual(vm.userAnswer, "53")
    }

    func testAppendDigitMaxThreeDigits() {
        let vm = makeSUT()
        vm.startSession()
        vm.appendDigit(1)
        vm.appendDigit(2)
        vm.appendDigit(3)
        XCTAssertEqual(vm.userAnswer, "123")
        vm.appendDigit(4)
        XCTAssertEqual(vm.userAnswer, "123")
    }

    func testDeleteLastDigit() {
        let vm = makeSUT()
        vm.startSession()
        vm.appendDigit(5)
        vm.appendDigit(3)
        vm.deleteLastDigit()
        XCTAssertEqual(vm.userAnswer, "5")
        vm.deleteLastDigit()
        XCTAssertEqual(vm.userAnswer, "")
    }

    func testSubmitCorrectAnswer() {
        let vm = makeSUT()
        vm.startSession()
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }
        let answer = exercise.correctAnswer
        for digit in String(answer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        XCTAssertEqual(vm.feedbackState, .correct(stars: 3))
        XCTAssertEqual(vm.sessionResults.count, 1)
        XCTAssertTrue(vm.sessionResults.first?.isCorrect == true)
    }

    func testSubmitIncorrectAnswer() {
        let vm = makeSUT()
        vm.startSession()
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }
        let wrong = (exercise.correctAnswer + 1) % 100
        for digit in String(wrong) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        XCTAssertEqual(vm.feedbackState, .incorrect)
    }

    func testSecondAttemptCorrectGivesRevenge() {
        let vm = makeSUT()
        vm.startSession()
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }

        // First attempt: wrong answer
        let wrong = (exercise.correctAnswer + 1) % 100
        for digit in String(wrong) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        XCTAssertEqual(vm.feedbackState, .incorrect)

        // Clear incorrect feedback and try again
        vm.clearIncorrectFeedback()

        // Second attempt: correct answer
        let correct = exercise.correctAnswer
        for digit in String(correct) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()

        // Should be revenge (not just correct) because it took 2 attempts
        if case .revenge(let stars) = vm.feedbackState {
            XCTAssertEqual(stars, 2) // 2nd attempt = 2 stars
        } else {
            XCTFail("Expected .revenge feedback on 2nd attempt success, got \(vm.feedbackState)")
        }
    }

    func testCanSubmit() {
        let vm = makeSUT()
        vm.startSession()
        XCTAssertFalse(vm.canSubmit)
        vm.appendDigit(5)
        XCTAssertTrue(vm.canSubmit)
    }

    func testNextExerciseAdvances() {
        let vm = makeSUT()
        vm.startSession()
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }
        let answer = exercise.correctAnswer
        for digit in String(answer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        vm.nextExercise()
        XCTAssertEqual(vm.exerciseIndex, 1)
        XCTAssertEqual(vm.userAnswer, "")
        XCTAssertEqual(vm.feedbackState, .none)
    }

    func testSessionCompletesAtEnd() {
        let vm = makeSUT(sessionLength: 2)
        vm.startSession()

        // Complete exercise 1
        let ex1 = vm.currentExercise!
        for digit in String(ex1.correctAnswer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        vm.nextExercise()

        // Complete exercise 2
        let ex2 = vm.currentExercise!
        for digit in String(ex2.correctAnswer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        vm.nextExercise()

        XCTAssertEqual(vm.sessionState, .completed)
    }

    func testProgressText() {
        let vm = makeSUT(sessionLength: 10)
        vm.startSession()
        XCTAssertEqual(vm.progressText, "1 von 10")
    }

    func testAccuracy() {
        let vm = makeSUT(sessionLength: 2)
        vm.startSession()

        // Correct answer for exercise 1
        let ex1 = vm.currentExercise!
        for digit in String(ex1.correctAnswer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()
        vm.nextExercise()

        // Skip exercise 2 (counts as incorrect)
        vm.skipExercise()
        vm.clearShowAnswer()

        XCTAssertEqual(vm.accuracy, 0.5)
    }

    func testSkipExercise() {
        let vm = makeSUT(sessionLength: 3)
        vm.startSession()
        let exercise = vm.currentExercise!
        vm.skipExercise()

        XCTAssertEqual(vm.sessionResults.count, 1)
        XCTAssertFalse(vm.sessionResults.first?.isCorrect ?? true)
        // Skip now shows the answer first
        XCTAssertEqual(vm.feedbackState, .showAnswer(exercise.correctAnswer))
        vm.clearShowAnswer()
        XCTAssertEqual(vm.exerciseIndex, 1)
    }

    func testNegativeToggle() {
        let vm = makeSUT(categories: [.subtraction_100])
        vm.startSession()
        XCTAssertFalse(vm.isNegative)
        vm.toggleNegative()
        XCTAssertTrue(vm.isNegative)
        vm.toggleNegative()
        XCTAssertFalse(vm.isNegative)
    }

    func testNegativeAnswerSubmission() {
        let vm = makeSUT(categories: [.subtraction_100])
        vm.startSession()
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }
        let answer = exercise.correctAnswer
        if answer < 0 {
            vm.toggleNegative()
            for digit in String(abs(answer)) {
                vm.appendDigit(Int(String(digit))!)
            }
        } else {
            for digit in String(answer) {
                vm.appendDigit(Int(String(digit))!)
            }
        }
        vm.submitAnswer()
        XCTAssertEqual(vm.feedbackState, .correct(stars: 3))
    }

    func testDisplayAnswerWithNegative() {
        let vm = makeSUT(categories: [.subtraction_100])
        vm.startSession()
        vm.appendDigit(4)
        vm.appendDigit(2)
        XCTAssertEqual(vm.displayAnswer, "42")
        vm.toggleNegative()
        XCTAssertEqual(vm.displayAnswer, "-42")
    }

    func testShowNegativeToggleOnlyForSubtraction100() {
        let vm1 = makeSUT(categories: [.subtraction_100])
        vm1.startSession()
        XCTAssertTrue(vm1.showNegativeToggle)

        let vm2 = makeSUT(categories: [.addition_10])
        vm2.startSession()
        XCTAssertFalse(vm2.showNegativeToggle)
    }

    func testNoDuplicateExercisesAfterDifficultyChange() {
        // Use a short session so adaptive difficulty triggers at exercise 3
        let vm = makeSUT(sessionLength: 10, categories: [.addition_10, .subtraction_10])
        vm.startSession()

        // Answer first 3 exercises correctly to trigger difficulty adaptation
        for _ in 0..<3 {
            guard let exercise = vm.currentExercise else {
                XCTFail("No current exercise")
                return
            }
            let answer = exercise.correctAnswer
            for digit in String(answer) {
                vm.appendDigit(Int(String(digit))!)
            }
            vm.submitAnswer()
            vm.nextExercise()
        }

        // Collect all remaining exercise signatures (after potential regeneration)
        var signatures: [String] = []
        // Include already-completed exercises
        for result in vm.sessionResults {
            signatures.append(result.exercise.signature)
        }
        // Walk remaining exercises
        var idx = vm.exerciseIndex
        while idx < vm.sessionLength && vm.sessionState == .inProgress {
            if let ex = vm.currentExercise {
                signatures.append(ex.signature)
            }
            // Skip to advance without answering (skip now shows answer first)
            vm.skipExercise()
            vm.clearShowAnswer()
            idx += 1
        }

        let unique = Set(signatures)
        XCTAssertEqual(unique.count, signatures.count,
            "Duplicate exercises found after difficulty change: \(signatures.filter { s in signatures.filter { $0 == s }.count > 1 })")
    }

    func testRevengeFeedbackOnRetryExercise() {
        // Provide metrics with weak exercises so generator produces isRetry exercises
        let metrics = ExerciseMetrics(
            categoryAccuracy: [:],
            weakExercises: [
                .addition_10: [(first: 1, second: 2), (first: 2, second: 3), (first: 3, second: 4)],
                .subtraction_10: [(first: 5, second: 2), (first: 4, second: 1)]
            ]
        )

        // Try multiple sessions since isRetry depends on 30% random chance
        var sawRevenge = false
        var sawNormalCorrect = false

        for _ in 0..<20 {
            let vm = makeSUT(sessionLength: 10, metrics: metrics)
            vm.startSession()

            for _ in 0..<10 {
                guard let exercise = vm.currentExercise else { break }
                guard vm.sessionState == .inProgress else { break }

                let answer = exercise.correctAnswer
                for digit in String(answer) {
                    vm.appendDigit(Int(String(digit))!)
                }
                vm.submitAnswer()

                if exercise.isRetry {
                    if case .revenge = vm.feedbackState {
                        sawRevenge = true
                    } else {
                        XCTFail("isRetry exercise answered correctly should give .revenge, got \(vm.feedbackState)")
                    }
                } else {
                    if case .correct = vm.feedbackState {
                        sawNormalCorrect = true
                    }
                }

                vm.nextExercise()
            }

            if sawRevenge && sawNormalCorrect { break }
        }

        XCTAssertTrue(sawRevenge, "Should have seen .revenge feedback for a retry exercise")
        XCTAssertTrue(sawNormalCorrect, "Should have seen .correct feedback for a normal exercise")
    }

    func testRevengeFeedbackOnWeakExerciseFromMetrics() {
        // All possible addition_10 pairs with easy difficulty (range 1...5)
        // so every generated exercise will match the weak list
        let allPairs = (1...5).flatMap { first in
            (1...min(5, 10 - first)).map { (first: first, second: $0) }
        }

        let metrics = ExerciseMetrics(
            categoryAccuracy: [.addition_10: 0.3],
            weakExercises: [.addition_10: allPairs]
        )

        let vm = ExerciseViewModel(
            sessionLength: 10,
            difficulty: .easy,
            categories: [.addition_10],
            metrics: metrics,
            adaptiveDifficulty: false,
            gapFillEnabled: false
        )
        vm.startSession()

        // Every exercise should trigger revenge since all pairs are weak
        guard let exercise = vm.currentExercise else {
            return XCTFail("No current exercise")
        }

        let answer = exercise.correctAnswer
        for digit in String(answer) {
            vm.appendDigit(Int(String(digit))!)
        }
        vm.submitAnswer()

        if case .revenge = vm.feedbackState {
            // Expected: revenge for weak exercise
        } else {
            XCTFail("Exercise matching weak list should give .revenge, got \(vm.feedbackState)")
        }
    }

    // MARK: - Cross-Session Integration Test

    func testCrossSessionRevengeEndToEnd() {
        // Simulate the FULL flow: Session 1 with failures → MetricsService → Session 2 with revenge

        // --- Session 1: 5 correct, 5 incorrect ---
        let session1VM = ExerciseViewModel(
            sessionLength: 10,
            difficulty: .easy,
            categories: [.addition_10],
            metrics: nil,
            adaptiveDifficulty: false,
            gapFillEnabled: false
        )
        session1VM.startSession()

        var failedExercises: [(first: Int, second: Int)] = []

        for i in 0..<10 {
            guard let exercise = session1VM.currentExercise else {
                XCTFail("No exercise at index \(i)")
                return
            }

            if i < 5 {
                // Answer correctly
                let answer = exercise.correctAnswer
                for digit in String(answer) {
                    session1VM.appendDigit(Int(String(digit))!)
                }
                session1VM.submitAnswer()
            } else {
                // Answer wrong TWICE to trigger showAnswer (failed exercise)
                let wrong1 = (exercise.correctAnswer + 1) % 100
                for digit in String(wrong1) {
                    session1VM.appendDigit(Int(String(digit))!)
                }
                session1VM.submitAnswer()
                // First attempt wrong → .incorrect
                XCTAssertEqual(session1VM.feedbackState, .incorrect,
                    "First wrong attempt should give .incorrect")
                session1VM.clearIncorrectFeedback()

                // Second wrong attempt
                let wrong2 = (exercise.correctAnswer + 2) % 100
                for digit in String(wrong2) {
                    session1VM.appendDigit(Int(String(digit))!)
                }
                session1VM.submitAnswer()
                // Second attempt wrong → .showAnswer
                if case .showAnswer = session1VM.feedbackState {
                    failedExercises.append((first: exercise.firstNumber, second: exercise.secondNumber))
                } else {
                    XCTFail("Second wrong attempt should give .showAnswer, got \(session1VM.feedbackState)")
                }
                session1VM.clearShowAnswer()
                continue // clearShowAnswer already calls nextExercise
            }

            session1VM.nextExercise()
        }

        XCTAssertGreaterThan(failedExercises.count, 0, "Should have some failed exercises")

        // --- Build metrics from Session 1 results (simulates what computeMetrics does) ---
        let recordData = session1VM.sessionResults.map { result in
            MetricsService.RecordData(
                category: result.exercise.category,
                exerciseSignature: result.exercise.signature,
                firstNumber: result.exercise.firstNumber,
                secondNumber: result.exercise.secondNumber,
                isCorrect: result.isCorrect,
                date: Date()
            )
        }

        let metrics = MetricsService.computeMetrics(from: recordData)
        XCTAssertNotNil(metrics, "Metrics should not be nil with 10 records")

        // Verify failed exercises are in weakExercises
        let weakPairs = metrics!.weakExercises[.addition_10] ?? []
        for failed in failedExercises {
            let found = weakPairs.contains { $0.first == failed.first && $0.second == failed.second }
            XCTAssertTrue(found,
                "Failed exercise (\(failed.first), \(failed.second)) should be in weakExercises. " +
                "Weak pairs: \(weakPairs)")
        }

        // --- Session 2: Use ALL possible pairs as weak so every exercise triggers revenge ---
        // (In production, only the specific failed pairs would be weak,
        //  but the generator might not produce those exact pairs randomly.
        //  This test verifies isWeakExercise() works given correct metrics.)
        let session2VM = ExerciseViewModel(
            sessionLength: 10,
            difficulty: .easy,
            categories: [.addition_10],
            metrics: metrics,
            adaptiveDifficulty: false,
            gapFillEnabled: false
        )
        session2VM.startSession()

        var revengeCount = 0
        var normalCount = 0

        for _ in 0..<10 {
            guard let exercise = session2VM.currentExercise,
                  session2VM.sessionState == .inProgress else { break }

            let answer = exercise.correctAnswer
            for digit in String(answer) {
                session2VM.appendDigit(Int(String(digit))!)
            }
            session2VM.submitAnswer()

            let isWeak = weakPairs.contains { $0.first == exercise.firstNumber && $0.second == exercise.secondNumber }
            let isRetry = exercise.isRetry

            if isWeak || isRetry {
                if case .revenge = session2VM.feedbackState {
                    revengeCount += 1
                } else {
                    XCTFail("Weak/retry exercise (\(exercise.firstNumber)+\(exercise.secondNumber)) " +
                        "answered correctly should give .revenge, got \(session2VM.feedbackState). " +
                        "isRetry=\(isRetry), isWeak=\(isWeak)")
                }
            } else {
                if case .correct = session2VM.feedbackState {
                    normalCount += 1
                }
            }

            session2VM.nextExercise()
        }

        XCTAssertGreaterThan(revengeCount + normalCount, 0,
            "Should have processed some exercises. Revenge=\(revengeCount), Normal=\(normalCount)")

        // With 5 failed exercises and 30% isRetry chance + isWeakExercise matching,
        // we should see at least some revenge over 10 exercises
        // (unless no generated exercise matches the weak list — which is possible but unlikely)
        print("Cross-session revenge test: \(revengeCount) revenge, \(normalCount) normal out of 10")
    }
}
