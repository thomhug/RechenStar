import SwiftUI

struct ExerciseView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel: ExerciseViewModel
    @State private var shakeOffset: CGFloat = 0
    @State private var autoAdvanceTask: DispatchWorkItem?

    let onSessionComplete: ([ExerciseResult]) -> Void
    let onCancel: () -> Void

    init(
        sessionLength: Int = 10,
        onSessionComplete: @escaping ([ExerciseResult]) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: ExerciseViewModel(sessionLength: sessionLength))
        self.onSessionComplete = onSessionComplete
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 8)
            progressSection
            exerciseCardSection
            answerDisplay
            feedbackSection
            Spacer()
            numberPad
            actionButtons
            Spacer().frame(height: 8)
        }
        .padding(20)
        .background(Color.appBackgroundGradient.ignoresSafeArea())
        .onAppear {
            viewModel.startSession()
        }
        .onChange(of: viewModel.sessionState) { _, newState in
            if newState == .completed {
                onSessionComplete(viewModel.sessionResults)
            }
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
                    onCancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.appTextSecondary.opacity(0.6))
                }
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
        Text(viewModel.userAnswer.isEmpty ? "_" : viewModel.userAnswer)
            .font(AppFonts.numberHuge)
            .foregroundColor(viewModel.userAnswer.isEmpty ? .appTextSecondary.opacity(0.4) : .appSkyBlue)
            .frame(height: 80)
            .offset(x: shakeOffset)
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        Group {
            switch viewModel.feedbackState {
            case .none:
                Color.clear.frame(height: 40)

            case .correct(let stars):
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.appSuccess)
                    ForEach(0..<stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.appSunYellow)
                    }
                }
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
                IconButton(icon: "delete.left", size: 24, color: .appCoral) {
                    viewModel.deleteLastDigit()
                }
                .frame(width: 80, height: 80)
                .disabled(!padEnabled)

                NumberPadButton(number: 0) { d in
                    viewModel.appendDigit(d)
                }
                .disabled(!padEnabled)

                IconButton(icon: "checkmark.circle.fill", size: 24, color: .appGrassGreen) {
                    submitWithFeedback()
                }
                .frame(width: 80, height: 80)
                .disabled(!viewModel.canSubmit)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        Group {
            switch viewModel.feedbackState {
            case .correct:
                AppButton(title: "Weiter", variant: .primary, icon: "arrow.right") {
                    cancelAutoAdvance()
                    viewModel.nextExercise()
                }
            case .none:
                SkipButton {
                    viewModel.skipExercise()
                }
            case .incorrect:
                Color.clear.frame(height: 60)
            }
        }
    }

    // MARK: - Helpers

    private func submitWithFeedback() {
        viewModel.submitAnswer()

        if viewModel.feedbackState == .incorrect {
            triggerShake()
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: task)
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
