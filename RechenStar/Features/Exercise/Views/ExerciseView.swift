import SwiftUI
import Combine

struct ExerciseView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AppState.self) private var appState
    @State private var viewModel: ExerciseViewModel
    @State private var shakeOffset: CGFloat = 0
    @State private var autoAdvanceTask: DispatchWorkItem?
    @State private var autoRevealTask: DispatchWorkItem?
    @State private var showBreakReminder = false
    @State private var sessionStartTime = Date()
    @State private var revengeStarsVisible = 0

    private let breakCheckTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    let hideSkipButton: Bool
    let autoShowAnswerSeconds: Int
    let onSessionComplete: ([ExerciseResult]) -> Void
    let onCancel: ([ExerciseResult]) -> Void

    init(
        sessionLength: Int = 10,
        difficulty: Difficulty = .easy,
        categories: [ExerciseCategory] = [.addition_10, .subtraction_10],
        metrics: ExerciseMetrics? = nil,
        adaptiveDifficulty: Bool = true,
        gapFillEnabled: Bool = true,
        hideSkipButton: Bool = false,
        autoShowAnswerSeconds: Int = 0,
        onSessionComplete: @escaping ([ExerciseResult]) -> Void,
        onCancel: @escaping ([ExerciseResult]) -> Void
    ) {
        _viewModel = State(initialValue: ExerciseViewModel(
            sessionLength: sessionLength,
            difficulty: difficulty,
            categories: categories,
            metrics: metrics,
            adaptiveDifficulty: adaptiveDifficulty,
            gapFillEnabled: gapFillEnabled
        ))
        self.hideSkipButton = hideSkipButton
        self.autoShowAnswerSeconds = autoShowAnswerSeconds
        self.onSessionComplete = onSessionComplete
        self.onCancel = onCancel
    }

    /// Whether the screen is compact (iPhone SE etc.)
    private var isCompact: Bool {
        UIScreen.main.bounds.height < 700
    }

    private var padButtonSize: CGFloat {
        isCompact ? 60 : 80
    }

    private var padSpacing: CGFloat {
        isCompact ? 8 : 12
    }

    var body: some View {
        ZStack {
            VStack(spacing: isCompact ? 6 : 12) {
                progressSection
                    .padding(.top, isCompact ? 4 : 10)
                exerciseCardSection
                answerDisplay
                feedbackSection
                Spacer(minLength: 0)
                numberPad
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            if viewModel.showEncouragement {
                VStack {
                    Text("Kein Problem! Wir machen mit leichteren Aufgaben weiter.")
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.appSkyBlue)
                        )
                        .padding(.horizontal, 30)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 80)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            viewModel.dismissEncouragement()
                        }
                    }
                }
                .animation(.spring(duration: 0.4), value: viewModel.showEncouragement)
            }
        }
        .background(Color.appBackgroundGradient.ignoresSafeArea())
        .onAppear {
            viewModel.startSession()
            startAutoRevealTimer()
        }
        .onChange(of: viewModel.sessionState) { _, newState in
            if newState == .completed {
                cancelAutoReveal()
                onSessionComplete(viewModel.sessionResults)
            }
        }
        .onChange(of: viewModel.exerciseIndex) { _, _ in
            startAutoRevealTimer()
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

    private var difficultyLabel: String {
        let label = viewModel.currentDifficulty.label
        return viewModel.adaptiveDifficulty ? "Auto: \(label)" : label
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.progressText)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.appTextSecondary)
                Spacer()
                Text(difficultyLabel)
                    .font(AppFonts.footnote)
                    .foregroundColor(.appTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.appTextSecondary.opacity(0.1))
                    )
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.appSunYellow)
                    Text("\(viewModel.totalStars)")
                        .font(AppFonts.subheadline)
                        .foregroundColor(.appTextPrimary)
                }
                Button {
                    cancelAutoReveal()
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
                let d = exercise.displayNumbers
                let isShowingAnswer: Bool = {
                    if case .showAnswer = viewModel.feedbackState { return true }
                    return false
                }()
                let revealedAnswer: Int? = {
                    if case .showAnswer(let ans) = viewModel.feedbackState { return ans }
                    return nil
                }()
                ExerciseCard(
                    leftText: d.left,
                    rightText: d.right,
                    resultText: d.result,
                    operation: exercise.type.symbol,
                    showResult: isShowingAnswer,
                    revealedAnswer: revealedAnswer
                )
            }
        }
    }

    // MARK: - Answer Display

    private var answerDisplay: some View {
        Text(viewModel.displayAnswer)
            .font(isCompact ? AppFonts.numberLarge : AppFonts.numberHuge)
            .foregroundColor(viewModel.userAnswer.isEmpty ? .appTextSecondary.opacity(0.4) : .appSkyBlue)
            .frame(height: isCompact ? 56 : 80)
            .offset(x: shakeOffset)
            .accessibilityIdentifier("answer-display")
            .accessibilityLabel(viewModel.userAnswer.isEmpty ? "Noch keine Antwort" : "Antwort: \(viewModel.displayAnswer)")
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        Group {
            switch viewModel.feedbackState {
            case .none:
                Color.clear.frame(height: isCompact ? 30 : 40)

            case .correct(let stars):
                HStack(spacing: 8) {
                    ForEach(0..<min(stars, 3), id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: isCompact ? 22 : 28))
                            .foregroundColor(.appSunYellow)
                            .scaleEffect(index < revengeStarsVisible ? 1.0 : 0.0)
                            .rotationEffect(.degrees(index < revengeStarsVisible ? 0 : -30))
                            .animation(
                                .spring(duration: 0.5, bounce: 0.6)
                                    .delay(Double(index) * 0.2),
                                value: revengeStarsVisible
                            )
                    }
                }
                .frame(height: isCompact ? 30 : 40)
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    revengeStarsVisible = min(stars, 3)
                }

            case .revenge(let stars):
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        ForEach(0..<min(stars, 3), id: \.self) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: isCompact ? 22 : 28))
                                .foregroundColor(.appSunYellow)
                                .scaleEffect(index < revengeStarsVisible ? 1.0 : 0.0)
                                .rotationEffect(.degrees(index < revengeStarsVisible ? 0 : -30))
                                .animation(
                                    .spring(duration: 0.5, bounce: 0.6)
                                        .delay(Double(index) * 0.2),
                                    value: revengeStarsVisible
                                )
                        }
                    }
                    Text("Stark! Du hast es geschafft!")
                        .font(isCompact ? AppFonts.subheadline : AppFonts.headline)
                        .foregroundColor(.appSunYellow)
                }
                .frame(height: isCompact ? 54 : 70)
                .accessibilityIdentifier("revenge-feedback")
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    revengeStarsVisible = min(stars, 3)
                }

            case .incorrect:
                Text("Versuch es nochmal!")
                    .font(isCompact ? AppFonts.subheadline : AppFonts.headline)
                    .foregroundColor(.appCoral)
                    .frame(height: isCompact ? 30 : 40)
                    .transition(.scale.combined(with: .opacity))

            case .wrongOperation(let correct, let wrong):
                Text("Achtung, \(correct) nicht \(wrong)!")
                    .font(isCompact ? AppFonts.subheadline : AppFonts.headline)
                    .foregroundColor(.appOrange)
                    .frame(height: isCompact ? 30 : 40)
                    .transition(.scale.combined(with: .opacity))

            case .showAnswer(let answer):
                Text("Die Antwort ist \(answer)")
                    .font(isCompact ? AppFonts.subheadline : AppFonts.headline)
                    .foregroundColor(.appGrassGreen)
                    .frame(height: isCompact ? 30 : 40)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.feedbackState)
    }

    // MARK: - Number Pad

    private var numberPad: some View {
        let padEnabled = viewModel.feedbackState == .none && !viewModel.isInputDisabled
        let btnSize = padButtonSize
        let iconSize = isCompact ? 20.0 : 24.0

        return VStack(spacing: padSpacing) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: padSpacing + 4) {
                    ForEach(1...3, id: \.self) { col in
                        let digit = row * 3 + col
                        NumberPadButton(number: digit, size: btnSize) { d in
                            viewModel.appendDigit(d)
                        }
                        .disabled(!padEnabled)
                    }
                }
            }
            HStack(spacing: padSpacing + 4) {
                if viewModel.showNegativeToggle {
                    Button {
                        viewModel.toggleNegative()
                    } label: {
                        Text("±")
                            .font(.system(size: btnSize * 0.35, weight: .bold))
                            .foregroundColor(viewModel.isNegative ? .white : .appSkyBlue)
                            .frame(width: btnSize, height: btnSize)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(viewModel.isNegative ? Color.appSkyBlue : Color.appCardBackground)
                            )
                    }
                    .disabled(!padEnabled)
                    .accessibilityIdentifier("negative-button")
                } else {
                    IconButton(icon: "delete.left", size: iconSize, color: .appCoral) {
                        viewModel.deleteLastDigit()
                    }
                    .frame(width: btnSize, height: btnSize)
                    .disabled(!padEnabled)
                    .accessibilityIdentifier("delete-button")
                }

                NumberPadButton(number: 0, size: btnSize) { d in
                    viewModel.appendDigit(d)
                }
                .disabled(!padEnabled)

                if viewModel.showNegativeToggle {
                    IconButton(icon: "delete.left", size: iconSize, color: .appCoral) {
                        viewModel.deleteLastDigit()
                    }
                    .frame(width: btnSize, height: btnSize)
                    .disabled(!padEnabled)
                    .accessibilityIdentifier("delete-button")
                } else {
                    IconButton(icon: "checkmark.circle.fill", size: iconSize, color: .appGrassGreen) {
                        submitWithFeedback()
                    }
                    .frame(width: btnSize, height: btnSize)
                    .disabled(!viewModel.canSubmit)
                    .accessibilityIdentifier("submit-button")
                }
            }

            if viewModel.showNegativeToggle {
                HStack {
                    Spacer()
                    IconButton(icon: "checkmark.circle.fill", size: iconSize, color: .appGrassGreen) {
                        submitWithFeedback()
                    }
                    .frame(width: btnSize, height: btnSize)
                    .disabled(!viewModel.canSubmit)
                    .accessibilityIdentifier("submit-button")
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        let btnHeight: CGFloat = isCompact ? 44 : 60
        return Group {
            switch viewModel.feedbackState {
            case .correct, .revenge:
                Color.clear.frame(height: btnHeight)
            case .none:
                if hideSkipButton {
                    Color.clear.frame(height: btnHeight)
                } else {
                    SkipButton {
                        skipWithFeedback()
                    }
                    .accessibilityIdentifier("skip-button")
                }
            case .incorrect, .wrongOperation:
                Color.clear.frame(height: btnHeight)
            case .showAnswer:
                Color.clear.frame(height: btnHeight)
            }
        }
    }

    // MARK: - Helpers

    private func submitWithFeedback() {
        cancelAutoReveal()
        viewModel.submitAnswer()

        switch viewModel.feedbackState {
        case .incorrect:
            if !themeManager.reducedMotion { triggerShake() }
            HapticFeedback.notification(.error)
            if themeManager.soundEnabled {
                SoundService.playIncorrect()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                viewModel.clearIncorrectFeedback()
            }

        case .wrongOperation:
            if !themeManager.reducedMotion { triggerShake() }
            HapticFeedback.notification(.warning)
            if themeManager.soundEnabled {
                SoundService.playOperationHint()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                viewModel.clearIncorrectFeedback()
            }

        case .showAnswer:
            if !themeManager.reducedMotion { triggerShake() }
            HapticFeedback.notification(.error)
            if themeManager.soundEnabled {
                SoundService.playIncorrect()
            }
            scheduleAutoAdvance(delay: 2.5, action: { viewModel.clearShowAnswer() })

        case .correct:
            HapticFeedback.notification(.success)
            if themeManager.soundEnabled {
                SoundService.playCorrect()
            }
            scheduleAutoAdvance(delay: 1.0, action: {
                revengeStarsVisible = 0
                viewModel.nextExercise()
            })

        case .revenge:
            HapticFeedback.notification(.success)
            if themeManager.soundEnabled {
                SoundService.playRevenge()
            }
            scheduleAutoAdvance(delay: 1.5, action: {
                revengeStarsVisible = 0
                viewModel.nextExercise()
            })

        case .none:
            break
        }
    }

    private func scheduleAutoAdvance(delay: Double = 1.5, action: @escaping () -> Void) {
        cancelAutoAdvance()
        let task = DispatchWorkItem {
            action()
        }
        autoAdvanceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
    }

    private func cancelAutoAdvance() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
    }

    private func skipWithFeedback() {
        cancelAutoReveal()
        viewModel.skipExercise()
        if themeManager.soundEnabled {
            SoundService.playIncorrect()
        }
        scheduleAutoAdvance(delay: 2.5, action: { viewModel.clearShowAnswer() })
    }

    private func startAutoRevealTimer() {
        cancelAutoReveal()
        guard autoShowAnswerSeconds > 0, viewModel.feedbackState == .none else { return }
        let task = DispatchWorkItem {
            viewModel.autoRevealAnswer()
            if !themeManager.reducedMotion { triggerShake() }
            HapticFeedback.notification(.error)
            if themeManager.soundEnabled {
                SoundService.playIncorrect()
            }
            scheduleAutoAdvance(delay: 2.5, action: { viewModel.clearShowAnswer() })
        }
        autoRevealTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(autoShowAnswerSeconds), execute: task)
    }

    private func cancelAutoReveal() {
        autoRevealTask?.cancel()
        autoRevealTask = nil
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
