# Design System - RechenStar

## Design-Philosophie

RechenStar folgt dem Prinzip der "Playful Simplicity" - spielerisch, aber nicht überladen; einfach, aber nicht langweilig.

## Farben

### Primary Palette

```swift
enum AppColors {
    // Primary
    static let skyBlue = Color(hex: "#4A90E2")      // Hauptfarbe
    static let sunYellow = Color(hex: "#F5D547")    // Erfolg, Sterne
    static let grassGreen = Color(hex: "#7ED321")   // Richtige Antwort

    // Secondary
    static let coral = Color(hex: "#FF6B6B")        // Akzente
    static let purple = Color(hex: "#9B59B6")       // Special Events
    static let orange = Color(hex: "#FFA500")       // Energie, Combos

    // Neutral
    static let darkGray = Color(hex: "#2C3E50")     // Text
    static let lightGray = Color(hex: "#ECF0F1")    // Hintergründe
    static let white = Color(hex: "#FFFFFF")        // Cards, Clean
}
```

### Semantic Colors

```swift
extension AppColors {
    // Feedback
    static let success = grassGreen
    static let warning = sunYellow
    static let error = coral
    static let info = skyBlue

    // UI Elements
    static let background = Color(hex: "#F7F9FC")
    static let cardBackground = white
    static let textPrimary = darkGray
    static let textSecondary = Color(hex: "#7F8C8D")
    static let border = Color(hex: "#E1E4E8")
}
```

### Dark Mode (Optional für Eltern-Bereich)

```swift
extension AppColors {
    static let darkBackground = Color(hex: "#1A1A2E")
    static let darkCard = Color(hex: "#16213E")
    static let darkText = Color(hex: "#E8E8E8")
}
```

## Typografie

### Font Stack

```swift
enum AppFonts {
    // Primary Font: SF Rounded für Freundlichkeit
    static let display = Font.custom("SF Rounded", size: 48).weight(.bold)
    static let title = Font.custom("SF Rounded", size: 32).weight(.bold)
    static let headline = Font.custom("SF Rounded", size: 24).weight(.semibold)
    static let body = Font.custom("SF Rounded", size: 20).weight(.medium)
    static let caption = Font.custom("SF Rounded", size: 16).weight(.regular)

    // Numbers: Extra groß und klar
    static let numberLarge = Font.custom("SF Rounded", size: 56).weight(.bold)
    static let numberMedium = Font.custom("SF Rounded", size: 40).weight(.bold)
    static let numberSmall = Font.custom("SF Rounded", size: 28).weight(.semibold)
}
```

### Text Styles

```swift
extension Text {
    func exerciseNumber() -> some View {
        self
            .font(AppFonts.numberLarge)
            .foregroundColor(AppColors.darkGray)
            .tracking(2)
    }

    func buttonLabel() -> some View {
        self
            .font(AppFonts.headline)
            .foregroundColor(.white)
            .textCase(.uppercase)
            .tracking(1)
    }
}
```

## Spacing & Layout

### Grid System

```swift
enum AppSpacing {
    static let xxs: CGFloat = 4   // Micro spacing
    static let xs: CGFloat = 8    // Tight spacing
    static let sm: CGFloat = 12   // Small spacing
    static let md: CGFloat = 16   // Default spacing
    static let lg: CGFloat = 24   // Medium spacing
    static let xl: CGFloat = 32   // Large spacing
    static let xxl: CGFloat = 48  // Huge spacing
    static let xxxl: CGFloat = 64 // Massive spacing
}
```

### Safe Areas & Margins

```swift
struct AppLayout {
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let minimumTappableSize: CGFloat = 44
    static let childTappableSize: CGFloat = 60
}
```

## Components

### Buttons

```swift
struct AppButton: View {
    enum Style {
        case primary, secondary, success, danger
    }

    let title: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.headline)
                .foregroundColor(textColor)
                .frame(minWidth: 200, minHeight: 60)
                .background(backgroundColor)
                .cornerRadius(AppRadius.large)
                .shadow(
                    color: .black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}
```

### Cards

```swift
struct AppCard: View {
    let content: AnyView

    var body: some View {
        content
            .padding(AppSpacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(AppRadius.medium)
            .shadow(
                color: .black.opacity(0.08),
                radius: 12,
                x: 0,
                y: 2
            )
    }
}
```

### Number Pad

```swift
struct NumberPadButton: View {
    let number: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(AppFonts.numberMedium)
                .foregroundColor(AppColors.darkGray)
                .frame(width: 80, height: 80)
                .background(AppColors.white)
                .cornerRadius(AppRadius.medium)
                .shadow(
                    color: .black.opacity(0.05),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        }
    }
}
```

## Icons & Illustrations

### Icon System

```swift
enum AppIcons {
    // SF Symbols verwendet
    static let star = "star.fill"
    static let starEmpty = "star"
    static let check = "checkmark.circle.fill"
    static let close = "xmark.circle.fill"
    static let home = "house.fill"
    static let settings = "gearshape.fill"
    static let parent = "person.2.fill"
    static let trophy = "trophy.fill"
    static let heart = "heart.fill"
    static let sound = "speaker.wave.2.fill"
    static let soundOff = "speaker.slash.fill"
}
```

### Character Illustrations

```
Sterni (Hauptcharakter):
- Gelber, lächelnder Stern
- Große, freundliche Augen
- Verschiedene Emotionen:
  * Happy (Standard)
  * Super Happy (3 Sterne)
  * Thinking (Wartet)
  * Encouraging (Bei Fehler)
```

## Animationen

### Standard Transitions

```swift
extension AnyTransition {
    static var appScale: AnyTransition {
        .scale.combined(with: .opacity)
    }

    static var appSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}
```

### Animation Timings

```swift
enum AppAnimations {
    static let instant: Animation = .easeInOut(duration: 0.2)
    static let quick: Animation = .spring(response: 0.3, dampingFraction: 0.8)
    static let normal: Animation = .spring(response: 0.5, dampingFraction: 0.8)
    static let slow: Animation = .easeInOut(duration: 0.8)

    // Celebration
    static let bounce: Animation = .interpolatingSpring(stiffness: 300, damping: 10)
    static let celebration: Animation = .spring(response: 0.6, dampingFraction: 0.6)
}
```

### Micro-Interactions

```swift
struct ButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

## Border Radius

```swift
enum AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xlarge: CGFloat = 32
    static let round: CGFloat = 9999
}
```

## Shadows & Elevation

```swift
enum AppShadows {
    static let small = Shadow(
        color: .black.opacity(0.05),
        radius: 4,
        x: 0,
        y: 2
    )

    static let medium = Shadow(
        color: .black.opacity(0.08),
        radius: 8,
        x: 0,
        y: 4
    )

    static let large = Shadow(
        color: .black.opacity(0.12),
        radius: 16,
        x: 0,
        y: 8
    )
}
```

## Feedback Patterns

### Visual Feedback

```swift
struct SuccessFeedback: View {
    var body: some View {
        VStack {
            Image(systemName: AppIcons.check)
                .font(.system(size: 80))
                .foregroundColor(AppColors.success)
                .transition(.scale)

            Text("Super gemacht!")
                .font(AppFonts.title)
                .foregroundColor(AppColors.success)
        }
        .padding(AppSpacing.xl)
        .background(
            AppColors.success.opacity(0.1)
                .cornerRadius(AppRadius.large)
        )
    }
}
```

### Haptic Feedback

```swift
enum HapticFeedback {
    static func success() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    static func error() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)
    }

    static func selection() {
        let selection = UISelectionFeedbackGenerator()
        selection.selectionChanged()
    }
}
```

## Accessibility Overrides

```swift
struct AccessibleNumberDisplay: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(AppFonts.numberLarge)
            .accessibilityLabel("\(number)")
            .accessibilityAddTraits(.isStaticText)
            .accessibilityValue("\(number)")
    }
}
```

## Responsive Design

```swift
extension View {
    func responsive() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 20)
    }
}
```

## Theme Configuration

```swift
class Theme: ObservableObject {
    @Published var colorScheme: ColorScheme = .light
    @Published var fontSize: FontSize = .normal
    @Published var reducedMotion: Bool = false
    @Published var highContrast: Bool = false

    enum FontSize: CGFloat {
        case small = 0.8
        case normal = 1.0
        case large = 1.2
        case extraLarge = 1.5
    }
}
```