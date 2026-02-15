import SwiftUI

// MARK: - App Card
struct AppCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat

    init(
        padding: CGFloat = 20,
        backgroundColor: Color = .appCardBackground,
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: shadowRadius,
                        x: 0,
                        y: 4
                    )
            )
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    let firstNumber: Int
    let secondNumber: Int
    let operation: String
    let showResult: Bool
    let result: Int?

    var body: some View {
        AppCard(padding: 30) {
            HStack(spacing: 20) {
                Text("\(firstNumber)")
                    .font(AppFonts.numberHuge)
                    .foregroundColor(.appTextPrimary)

                Text(operation)
                    .font(AppFonts.numberLarge)
                    .foregroundColor(.appSkyBlue)

                Text("\(secondNumber)")
                    .font(AppFonts.numberHuge)
                    .foregroundColor(.appTextPrimary)

                Text("=")
                    .font(AppFonts.numberLarge)
                    .foregroundColor(.appTextSecondary)

                if showResult, let result {
                    Text("\(result)")
                        .font(AppFonts.numberHuge)
                        .foregroundColor(.appSuccess)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("?")
                        .font(AppFonts.numberHuge)
                        .foregroundColor(.appTextSecondary)
                        .opacity(0.5)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityIdentifier("exercise-card")
        }
        .animation(.spring(duration: 0.4, bounce: 0.3), value: showResult)
    }

    private var accessibilityDescription: String {
        let resultText = showResult && result != nil ? "\(result!)" : "unbekannt"
        return "\(firstNumber) \(operation) \(secondNumber) gleich \(resultText)"
    }
}

// MARK: - Progress Card
struct ProgressCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        AppCard(padding: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.caption)
                        .foregroundColor(.appTextSecondary)

                    Text(value)
                        .font(AppFonts.headline)
                        .foregroundColor(.appTextPrimary)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppFonts.footnote)
                            .foregroundColor(.appTextSecondary)
                    }
                }

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title): \(value)")
        }
    }
}

// MARK: - Achievement Data
struct AchievementData {
    let title: String
    let description: String
    let icon: String
    let progress: Double // 0.0 to 1.0
    var progressText: String? = nil
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: AchievementData
    let isUnlocked: Bool

    var body: some View {
        AppCard(
            backgroundColor: isUnlocked ? .appCardBackground : .gray.opacity(0.1),
            shadowRadius: isUnlocked ? 10 : 2
        ) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color.appSunYellow.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(isUnlocked ? .appSunYellow : .gray)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(achievement.title)
                        .font(AppFonts.headline)
                        .foregroundColor(isUnlocked ? .appTextPrimary : .gray)

                    Text(achievement.description)
                        .font(AppFonts.caption)
                        .foregroundColor(isUnlocked ? .appTextSecondary : .gray.opacity(0.7))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        ProgressBarView(
                            progress: achievement.progress,
                            color: isUnlocked ? .appSunYellow : .gray
                        )
                        if let progressText = achievement.progressText {
                            Text(progressText)
                                .font(AppFonts.caption)
                                .foregroundColor(isUnlocked ? .appTextSecondary : .gray.opacity(0.7))
                                .fixedSize()
                        }
                    }
                }

                Spacer()

                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.appGrassGreen)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
        }
        .accessibilityLabel("\(achievement.title), \(isUnlocked ? "freigeschaltet" : "gesperrt"), \(Int(achievement.progress * 100)) Prozent")
    }
}

// MARK: - Progress Bar
struct ProgressBarView: View {
    let progress: Double
    let color: Color
    let height: CGFloat

    init(progress: Double, color: Color, height: CGFloat = 8) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: height)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Sticker Rarity
enum StickerRarity {
    case common, uncommon, rare, epic, legendary

    var color: Color {
        switch self {
        case .common: .gray
        case .uncommon: .appGrassGreen
        case .rare: .appSkyBlue
        case .epic: .appPurple
        case .legendary: .appSunYellow
        }
    }

    var starCount: Int {
        switch self {
        case .common: 1
        case .uncommon: 2
        case .rare: 3
        case .epic: 4
        case .legendary: 5
        }
    }
}

// MARK: - Sticker Card
struct StickerCard: View {
    let stickerName: String
    let isUnlocked: Bool
    let rarity: StickerRarity

    var body: some View {
        AppCard(
            padding: 8,
            backgroundColor: isUnlocked ? .white : .gray.opacity(0.1),
            cornerRadius: 12,
            shadowRadius: isUnlocked ? 6 : 2
        ) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isUnlocked ? rarity.color.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: isUnlocked ? "star.fill" : "questionmark")
                        .font(.system(size: isUnlocked ? 40 : 30))
                        .foregroundColor(isUnlocked ? rarity.color : .gray)
                }

                Text(isUnlocked ? stickerName : "???")
                    .font(AppFonts.footnote)
                    .foregroundColor(isUnlocked ? .appTextPrimary : .gray)
                    .lineLimit(1)

                HStack(spacing: 2) {
                    ForEach(0..<rarity.starCount, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(isUnlocked ? rarity.color : .gray)
                    }
                }
            }
        }
        .frame(width: 100, height: 140)
        .accessibilityLabel(isUnlocked ? "\(stickerName), Seltenheit \(rarity.starCount) Sterne" : "Unbekannter Sticker")
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let title: String
    let message: String
    let type: InfoType

    enum InfoType {
        case info, success, warning, error

        var color: Color {
            switch self {
            case .info: .appInfo
            case .success: .appSuccess
            case .warning: .appWarning
            case .error: .appError
            }
        }

        var icon: String {
            switch self {
            case .info: "info.circle.fill"
            case .success: "checkmark.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .error: "xmark.circle.fill"
            }
        }
    }

    var body: some View {
        AppCard(
            backgroundColor: type.color.opacity(0.1),
            cornerRadius: 16
        ) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(type.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.headline)
                        .foregroundColor(.appTextPrimary)

                    Text(message)
                        .font(AppFonts.body)
                        .foregroundColor(.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ExerciseCard(
                firstNumber: 3,
                secondNumber: 4,
                operation: "+",
                showResult: false,
                result: nil
            )

            ProgressCard(
                title: "Heutige Aufgaben",
                value: "15",
                subtitle: "5 mehr als gestern",
                icon: "checkmark.circle.fill",
                color: .appSuccess
            )

            AchievementCard(
                achievement: AchievementData(
                    title: "Mathe-Meister",
                    description: "Löse 100 Aufgaben",
                    icon: "trophy.fill",
                    progress: 0.75
                ),
                isUnlocked: true
            )

            HStack(spacing: 12) {
                StickerCard(
                    stickerName: "Goldener Stern",
                    isUnlocked: true,
                    rarity: .legendary
                )

                StickerCard(
                    stickerName: "???",
                    isUnlocked: false,
                    rarity: .rare
                )
            }

            InfoCard(
                title: "Gut gemacht!",
                message: "Du hast heute schon 10 Aufgaben gelöst!",
                type: .success
            )
        }
        .padding()
    }
    .background(Color.appBackground)
}
