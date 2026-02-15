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
    @State private var starCounterFrame: CGRect = .zero
    @State private var feedbackFrame: CGRect = .zero
    @State private var showStarAnimation = false
    @State private var animatingStars = 0

    private let breakCheckTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    let onSessionComplete: ([ExerciseResult]) -> Void
    let onCancel: ([ExerciseResult]) -> Void

    init(
        sessionLength: Int = 10,
        onSessionComplete: @escaping ([ExerciseResult]) -> Void,
        onCancel: @escaping ([ExerciseResult]) -> Void
    ) {
        _viewModel = State(initialValue: ExerciseViewModel(sessionLength: sessionLength))
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
            .coordinateSpace(name: "exercise")

            if showStarAnimation {
                StarAnimationView(
                    starCount: animatingStars,
                    from: feedbackFrame,
                    to: starCounterFrame
                ) {
                    showStarAnimation = false
                }
            }
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
        .onChange(of: viewModel.feedbackState) { _, newState in
            if newState == .none {
                showStarAnimation = false
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
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: StarCounterFrameKey.self,
                            value: geo.frame(in: .named("exercise"))
                        )
                    }
                )
                .onPreferenceChange(StarCounterFrameKey.self) { frame in
                    starCounterFrame = frame
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
        Text(viewModel.userAnswer.isEmpty ? "_" : viewModel.userAnswer)
            .font(AppFonts.numberHuge)
            .foregroundColor(viewModel.userAnswer.isEmpty ? .appTextSecondary.opacity(0.4) : .appSkyBlue)
            .frame(height: 80)
            .offset(x: shakeOffset)
            .accessibilityIdentifier("answer-display")
            .accessibilityLabel(viewModel.userAnswer.isEmpty ? "Noch keine Antwort" : "Antwort: \(viewModel.userAnswer)")
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
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: FeedbackFrameKey.self,
                            value: geo.frame(in: .named("exercise"))
                        )
                    }
                )
                .onPreferenceChange(FeedbackFrameKey.self) { frame in
                    feedbackFrame = frame
                }
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
                .accessibilityIdentifier("delete-button")

                NumberPadButton(number: 0) { d in
                    viewModel.appendDigit(d)
                }
                .disabled(!padEnabled)

                IconButton(icon: "checkmark.circle.fill", size: 24, color: .appGrassGreen) {
                    submitWithFeedback()
                }
                .frame(width: 80, height: 80)
                .disabled(!viewModel.canSubmit)
                .accessibilityIdentifier("submit-button")
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
                .accessibilityIdentifier("continue-button")
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

            if case .correct(let stars) = viewModel.feedbackState,
               !themeManager.reducedMotion {
                animatingStars = stars
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showStarAnimation = true
                }
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

// MARK: - Preference Keys

private struct StarCounterFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct FeedbackFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
