import SwiftUI

struct SessionCompleteView: View {
    let results: [ExerciseResult]
    let sessionLength: Int
    let onDismiss: () -> Void

    private var totalStars: Int {
        results.reduce(0) { $0 + $1.stars }
    }

    private var maxStars: Int {
        sessionLength * 3
    }

    private var correctCount: Int {
        results.filter(\.isCorrect).count
    }

    private var accuracy: Double {
        guard !results.isEmpty else { return 0 }
        return Double(correctCount) / Double(results.count)
    }

    private var motivationText: String {
        switch accuracy {
        case 0.9...: return "Fantastisch!"
        case 0.7..<0.9: return "Super!"
        case 0.5..<0.7: return "Gut gemacht!"
        default: return "Nicht aufgeben!"
        }
    }

    private var motivationIcon: String {
        switch accuracy {
        case 0.9...: return "star.circle.fill"
        case 0.7..<0.9: return "hand.thumbsup.fill"
        case 0.5..<0.7: return "face.smiling.fill"
        default: return "heart.fill"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Geschafft!")
                .font(AppFonts.display)
                .foregroundColor(.appSkyBlue)

            // Stars
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(0..<min(totalStars, 5), id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.appSunYellow)
                    }
                }

                Text("\(totalStars) von \(maxStars) Sternen")
                    .font(AppFonts.headline)
                    .foregroundColor(.appTextPrimary)
            }

            // Stats
            HStack(spacing: 16) {
                AppCard(padding: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.appSuccess)
                        Text("\(correctCount)/\(results.count)")
                            .font(AppFonts.headline)
                            .foregroundColor(.appTextPrimary)
                        Text("Richtig")
                            .font(AppFonts.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                AppCard(padding: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "percent")
                            .font(.system(size: 28))
                            .foregroundColor(.appSkyBlue)
                        Text("\(Int(accuracy * 100))%")
                            .font(AppFonts.headline)
                            .foregroundColor(.appTextPrimary)
                        Text("Genauigkeit")
                            .font(AppFonts.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)

            // Motivation
            AppCard {
                HStack(spacing: 12) {
                    Image(systemName: motivationIcon)
                        .font(.system(size: 36))
                        .foregroundColor(.appSunYellow)
                    Text(motivationText)
                        .font(AppFonts.title)
                        .foregroundColor(.appTextPrimary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)

            Spacer()

            AppButton(title: "Weiter", variant: .primary, icon: "house.fill") {
                onDismiss()
            }
        }
        .padding(20)
        .background(Color.appBackgroundGradient.ignoresSafeArea())
    }
}
