import SwiftUI

// MARK: - App Fonts
// Uses the system font with rounded design — NOT a custom font.
// Font.system(size:weight:design:.rounded) gives us SF Pro Rounded.
struct AppFonts {
    // Display & Titles
    static let display = Font.system(size: 48, weight: .bold, design: .rounded)
    static let title = Font.system(size: 32, weight: .bold, design: .rounded)
    static let headline = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let subheadline = Font.system(size: 20, weight: .semibold, design: .rounded)

    // Body Text
    static let body = Font.system(size: 18, weight: .medium, design: .rounded)
    static let bodyLarge = Font.system(size: 20, weight: .medium, design: .rounded)
    static let caption = Font.system(size: 16, weight: .regular, design: .rounded)
    static let footnote = Font.system(size: 14, weight: .regular, design: .rounded)

    // Numbers (extra large for exercises)
    static let numberHuge = Font.system(size: 64, weight: .bold, design: .rounded)
    static let numberLarge = Font.system(size: 56, weight: .bold, design: .rounded)
    static let numberMedium = Font.system(size: 40, weight: .bold, design: .rounded)
    static let numberSmall = Font.system(size: 28, weight: .semibold, design: .rounded)

    // Buttons
    static let buttonLarge = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let buttonMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let buttonSmall = Font.system(size: 16, weight: .medium, design: .rounded)
}

// MARK: - Font Modifiers
extension Text {
    func exerciseNumberStyle() -> some View {
        self
            .font(AppFonts.numberLarge)
            .foregroundColor(.appTextPrimary)
            .tracking(2)
    }

    func buttonLabelStyle() -> some View {
        self
            .font(AppFonts.buttonLarge)
            .foregroundColor(.white)
            .textCase(.uppercase)
            .tracking(1)
    }

    func successTextStyle() -> some View {
        self
            .font(AppFonts.title)
            .foregroundColor(.appSuccess)
            .multilineTextAlignment(.center)
    }

    func errorTextStyle() -> some View {
        self
            .font(AppFonts.headline)
            .foregroundColor(.appError)
            .multilineTextAlignment(.center)
    }

    func captionStyle() -> some View {
        self
            .font(AppFonts.caption)
            .foregroundColor(.appTextSecondary)
    }
}

// MARK: - Dynamic Type Support
struct ScaledFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    var size: CGFloat
    var weight: Font.Weight

    func body(content: Content) -> some View {
        let scaledSize = UIFontMetrics.default.scaledValue(for: size)
        return content.font(.system(size: scaledSize, weight: weight, design: .rounded))
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(ScaledFont(size: size, weight: weight))
    }
}

// MARK: - Accessibility Font Adjustments
struct AccessibilityFontAdjustment: ViewModifier {
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

extension View {
    func accessibleFont() -> some View {
        modifier(AccessibilityFontAdjustment())
    }
}

// MARK: - UIFont Extension (for UIKit appearance APIs)
extension UIFont {
    static func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return systemFont
    }
}
