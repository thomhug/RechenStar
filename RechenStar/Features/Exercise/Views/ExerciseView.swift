import SwiftUI
import Combine

struct ExerciseView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AppState.self) private var appState
    @State private var viewModel: ExerciseViewModel
    @State private var shakeOffset: CGFloat = 0
    @State private var autoAdvanceTask: DispatchWorkItem?
    @State private var showBreakReminder = false
    @State private var sessionStartTime = Date()

    private let breakCheckTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    let onSessionComplete: ([ExerciseResult]) -> Void
    let onCancel: ([ExerciseResult]) -> Void

    init(
        sessionLength: Int = 10,
        difficulty: Difficulty = .easy,
        categories: [ExerciseCategory] = [.addition_10, .subtraction_10],
        onSessionComplete: @escaping ([ExerciseResult]) -> Void,
        onCancel: @escaping ([ExerciseResult]) -> Void
    ) {
        _viewModel = State(initialValue: ExerciseViewModel(
            sessionLength: sessionLength,
            difficulty: difficulty,
            categories: categories
        ))
        self.onSessionComplete = onSessionComplete
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                progressSection
                    .padding(.top, 10)
                exerciseCardSection
                answerDisplay
                feedbackSection
                Spacer(minLength: 0)
                numberPad
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

        }
        .background(Color.appBackgroundGradient.ignoresSafeArea())
        .onAppear {
            viewModel.startSession()
        }
        .onChange(of: viewModel.sessionState) { _, newState in
            if newState == .completed {
                onSessionComplete(viewModel.sessionResults)
            }
        }
        .onReceive(breakCheckTimer) { _ in
            guard let prefs = appState.currentUser?.preferences,
                  prefs.breakReminder else { return }
            let elapsed = Date().timeIntervalSince(sessionStartTime)
            if elapsed >= Double(prefs.breakIntervalSeconds) && !showBreakReminder {
                showBreakReminder = true
            }
        }
        .alert("Zeit für eine Pause!", isPresented: $showBreakReminder) {
            Button("Weiter spielen") {
                sessionStartTime = Date()
            }
            Button("Pause machen") {
                onCancel(viewModel.sessionResults)
            }
        } message: {
            Text("Du spielst schon eine Weile. Eine kurze Pause tut gut!")
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.progressText)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.appTextSecondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.appSunYellow)
                    Text("\(viewModel.totalStars)")
                        .font(AppFonts.subheadline)
                        .foregroundColor(.appTextPrimary)
                }
                Button {
                    onCancel(viewModel.sessionResults)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.appTextSecondary.opacity(0.6))
                }
                .accessibilityLabel("Abbrechen")
                .accessibilityIdentifier("cancel-button")
                .padding(.leading, 8)
            }
            ProgressBarView(
                progress: viewModel.progressFraction,
                color: .appSkyBlue,
                height: 10
            )
        }
    }

    // MARK: - Exercise Card

    private var exerciseCardSection: some View {
        Group {
            if let exercise = viewModel.currentExercise {
                ExerciseCard(
                    firstNumber: exercise.firstNumber,
                    secondNumber: exercise.secondNumber,
                    operation: exercise.type.symbol,
                    showResult: false,
                    result: nil
                )
            }
        }
    }

    // MARK: - Answer Display

    private var answerDisplay: some View {
        Text(viewModel.displayAnswer)
            .font(AppFonts.numberHuge)
            .foregroundColor(viewModel.userAnswer.isEmpty ? .appTextSecondary.opacity(0.4) : .appSkyBlue)
            .frame(height: 80)
            .offset(x: shakeOffset)
            .accessibilityIdentifier("answer-display")
            .accessibilityLabel(viewModel.userAnswer.isEmpty ? "Noch keine Antwort" : "Antwort: \(viewModel.displayAnswer)")
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        Group {
            switch viewModel.feedbackState {
            case .none:
                Color.clear.frame(height: 40)

            case .correct:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.appSuccess)
                    .frame(height: 40)
                    .transition(.scale.combined(with: .opacity))

            case .incorrect:
                Text("Versuch es nochmal!")
                    .font(AppFonts.headline)
                    .foregroundColor(.appCoral)
                    .frame(height: 40)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.feedbackState)
    }

    // MARK: - Number Pad

    private var numberPad: some View {
        let padEnabled = viewModel.feedbackState == .none

        return VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 16) {
                    ForEach(1...3, id: \.self) { col in
                        let digit = row * 3 + col
                        NumberPadButton(number: digit) { d in
                            viewModel.appendDigit(d)
                        }
                        .disabled(!padEnabled)
                    }
                }
            }
            HStack(spacing: 16) {
                if viewModel.showNegativeToggle {
                    Button {
                        viewModel.toggleNegative()
                    } label: {
                        Text("±")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(viewModel.isNegative ? .white : .appSkyBlue)
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(viewModel.isNegative ? Color.appSkyBlue : Color.appCardBackground)
                            )
                    }
                    .disabled(!padEnabled)
                    .accessibilityIdentifier("negative-button")
                } else {
                    IconButton(icon: "delete.left", size: 24, color: .appCoral) {
                        viewModel.deleteLastDigit()
                    }
                    .frame(width: 80, height: 80)
                    .disabled(!padEnabled)
                    .accessibilityIdentifier("delete-button")
                }

                NumberPadButton(number: 0) { d in
                    viewModel.appendDigit(d)
                }
                .disabled(!padEnabled)

                if viewModel.showNegativeToggle {
                    IconButton(icon: "delete.left", size: 24, color: .appCoral) {
                        viewModel.deleteLastDigit()
                    }
                    .frame(width: 80, height: 80)
                    .disabled(!padEnabled)
                    .accessibilityIdentifier("delete-button")
                } else {
                    IconButton(icon: "checkmark.circle.fill", size: 24, color: .appGrassGreen) {
                        submitWithFeedback()
                    }
                    .frame(width: 80, height: 80)
                    .disabled(!viewModel.canSubmit)
                    .accessibilityIdentifier("submit-button")
                }
            }

            if viewModel.showNegativeToggle {
                HStack {
                    Spacer()
                    IconButton(icon: "checkmark.circle.fill", size: 24, color: .appGrassGreen) {
                        submitWithFeedback()
                    }
                    .frame(width: 80, height: 80)
                    .disabled(!viewModel.canSubmit)
                    .accessibilityIdentifier("submit-button")
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        Group {
            switch viewModel.feedbackState {
            case .correct:
                Color.clear.frame(height: 60)
            case .none:
                SkipButton {
                    viewModel.skipExercise()
                }
                .accessibilityIdentifier("skip-button")
            case .incorrect:
                Color.clear.frame(height: 60)
            }
        }
    }

    // MARK: - Helpers

    private func submitWithFeedback() {
        viewModel.submitAnswer()

        if viewModel.feedbackState == .incorrect {
            if !themeManager.reducedMotion { triggerShake() }
            HapticFeedback.notification(.error)
            if themeManager.soundEnabled {
                SoundService.playIncorrect()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                viewModel.clearIncorrectFeedback()
            }
        } else {
            HapticFeedback.notification(.success)
            if themeManager.soundEnabled {
                SoundService.playCorrect()
            }

            scheduleAutoAdvance()
        }
    }

    private func scheduleAutoAdvance() {
        cancelAutoAdvance()
        let task = DispatchWorkItem {
            viewModel.nextExercise()
        }
        autoAdvanceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: task)
    }

    private func cancelAutoAdvance() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
    }

    private func triggerShake() {
        let offsets: [(CGFloat, Double)] = [
            (-10, 0.05), (10, 0.1), (-8, 0.15), (8, 0.2), (-4, 0.25), (0, 0.3)
        ]
        for (offset, delay) in offsets {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: 0.05)) {
                    shakeOffset = offset
                }
            }
        }
    }
}
