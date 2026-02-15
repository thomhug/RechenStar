import SwiftUI

// MARK: - Bounce Button Style
// Replaces the fragile onLongPressGesture hack with a proper SwiftUI ButtonStyle.
struct BounceButtonStyle: SwiftUI.ButtonStyle {
    var scaleOnPress: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleOnPress : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Haptic Feedback
enum HapticFeedback {
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "hapticEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "hapticEnabled")
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// MARK: - Button Variant
enum AppButtonVariant {
    case primary
    case secondary
    case success
    case danger
    case ghost

    var backgroundColor: Color {
        switch self {
        case .primary: .appSkyBlue
        case .secondary: .appPurple
        case .success: .appGrassGreen
        case .danger: .appCoral
        case .ghost: .clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .ghost: .appSkyBlue
        default: .white
        }
    }
}

// MARK: - App Button
struct AppButton: View {
    let title: String
    let variant: AppButtonVariant
    let icon: String?
    let action: () -> Void
    let isLoading: Bool

    @Environment(\.isEnabled) private var isEnabled

    init(
        title: String,
        variant: AppButtonVariant = .primary,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button {
            HapticFeedback.impact()
            action()
        } label: {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: variant.foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                }

                Text(title)
                    .font(AppFonts.buttonLarge)
            }
            .foregroundColor(isEnabled ? variant.foregroundColor : .gray)
            .frame(minWidth: 200, minHeight: 60)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(isEnabled ? variant.backgroundColor : Color.gray.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(variant == .ghost ? variant.backgroundColor : .clear, lineWidth: 2)
            )
            .shadow(
                color: isEnabled ? .black.opacity(0.1) : .clear,
                radius: 8, y: 4
            )
        }
        .buttonStyle(BounceButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - Number Pad Button
struct NumberPadButton: View {
    let number: Int
    let action: (Int) -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(number: Int, action: @escaping (Int) -> Void) {
        self.number = number
        self.action = action
    }

    var body: some View {
        Button {
            HapticFeedback.selection()
            action(number)
        } label: {
            Text("\(number)")
                .font(AppFonts.numberMedium)
                .foregroundColor(isEnabled ? .appTextPrimary : .gray)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(isEnabled ? Color.white : Color.gray.opacity(0.1))
                        .shadow(
                            color: isEnabled ? .black.opacity(0.05) : .clear,
                            radius: 4, y: 2
                        )
                )
        }
        .buttonStyle(BounceButtonStyle(scaleOnPress: 0.9))
        .accessibilityLabel("\(number)")
        .accessibilityIdentifier("number-pad-\(number)")
    }
}

// MARK: - Icon Button
struct IconButton: View {
    let icon: String
    let action: () -> Void
    let size: CGFloat
    let color: Color

    init(
        icon: String,
        size: CGFloat = 24,
        color: Color = .appSkyBlue,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }

    var body: some View {
        Button {
            HapticFeedback.impact(.light)
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(color)
                .frame(width: size * 2, height: size * 2)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
        }
        .buttonStyle(BounceButtonStyle(scaleOnPress: 0.85))
    }
}

// MARK: - Submit Button
struct SubmitButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        AppButton(
            title: "Fertig!",
            variant: .success,
            icon: "checkmark.circle.fill",
            action: action
        )
        .disabled(!isEnabled)
    }
}

// MARK: - Skip Button
struct SkipButton: View {
    let action: () -> Void

    var body: some View {
        AppButton(
            title: "Überspringen",
            variant: .ghost,
            icon: "forward.fill",
            action: action
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AppButton(title: "Spielen", variant: .primary, icon: "play.fill") {}
        AppButton(title: "Weiter", variant: .secondary) {}
        AppButton(title: "Richtig!", variant: .success, icon: "checkmark") {}
        AppButton(title: "Löschen", variant: .danger) {}
        AppButton(title: "Überspringen", variant: .ghost) {}
        AppButton(title: "Deaktiviert") {}.disabled(true)
        AppButton(title: "Lädt...", isLoading: true) {}

        HStack(spacing: 20) {
            ForEach(0..<5) { number in
                NumberPadButton(number: number) { _ in }
            }
        }
    }
    .padding()
    .background(Color.appBackground)
}
