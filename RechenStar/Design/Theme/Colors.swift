import SwiftUI

// MARK: - App Colors
extension Color {
    // Primary Colors (same in light & dark)
    static let appSkyBlue = Color(hex: "#4A90E2")
    static let appSunYellow = Color(hex: "#F5D547")
    static let appGrassGreen = Color(hex: "#7ED321")

    // Secondary Colors (same in light & dark)
    static let appCoral = Color(hex: "#FF6B6B")
    static let appPurple = Color(hex: "#9B59B6")
    static let appOrange = Color(hex: "#FFA500")

    // Neutral Colors
    static let appDarkGray = Color(hex: "#2C3E50")
    static let appLightGray = Color(hex: "#ECF0F1")
    static let appWhite = Color(hex: "#FFFFFF")

    // Semantic Colors
    static let appSuccess = appGrassGreen
    static let appWarning = appSunYellow
    static let appError = appCoral
    static let appInfo = appSkyBlue

    // Adaptive UI Colors (light/dark)
    static let appBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#1A1A2E")
            : UIColor(hex: "#F7F9FC")
    })

    static let appBackgroundBottom = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#16213E")
            : UIColor.white
    })

    static let appCardBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#1E2A45")
            : UIColor.white
    })

    static let appTextPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#E8E8E8")
            : UIColor(hex: "#2C3E50")
    })

    static let appTextSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#A0A0B0")
            : UIColor(hex: "#7F8C8D")
    })

    static let appBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#2E3A52")
            : UIColor(hex: "#E1E4E8")
    })

    // Gradients
    static let appPrimaryGradient = LinearGradient(
        colors: [appSkyBlue, appSkyBlue.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let appSuccessGradient = LinearGradient(
        colors: [appGrassGreen, appGrassGreen.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let appBackgroundGradient = LinearGradient(
        colors: [appBackground, appBackgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor Extension for Hex
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: 1
        )
    }
}

// MARK: - Accessibility Color Palettes
// Based on Bang Wong's color-blind-safe palette (Nature Methods, 2011)
struct AccessibilityColors {
    // High Contrast Mode
    static let highContrastPrimary = Color.black
    static let highContrastSecondary = Color.white
    static let highContrastAccent = Color.blue

    // Protanopia (red-blind): reds appear darker/brownish
    struct Protanopia {
        static let primary = Color(hex: "#0173B2")
        static let success = Color(hex: "#56B4E9")
        static let warning = Color(hex: "#E69F00")
        static let error = Color(hex: "#CC79A7")
    }

    // Deuteranopia (green-blind): greens shift toward yellow/brown
    struct Deuteranopia {
        static let primary = Color(hex: "#332288")
        static let success = Color(hex: "#44AA99")
        static let warning = Color(hex: "#DDCC77")
        static let error = Color(hex: "#CC6677")
    }

    // Tritanopia (blue-blind): blues shift toward green, yellows toward pink
    struct Tritanopia {
        static let primary = Color(hex: "#E69F00")
        static let success = Color(hex: "#56B4E9")
        static let warning = Color(hex: "#009E73")
        static let error = Color(hex: "#CC79A7")
    }
}

// MARK: - Color Theme
protocol ColorTheme {
    var primary: Color { get }
    var secondary: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var background: Color { get }
    var surface: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
}

struct DefaultColorTheme: ColorTheme {
    let primary = Color.appSkyBlue
    let secondary = Color.appPurple
    let success = Color.appGrassGreen
    let warning = Color.appSunYellow
    let error = Color.appCoral
    let background = Color.appBackground
    let surface = Color.appCardBackground
    let textPrimary = Color.appTextPrimary
    let textSecondary = Color.appTextSecondary
}

struct DarkColorTheme: ColorTheme {
    let primary = Color(hex: "#5BA0F2")
    let secondary = Color(hex: "#B07ACC")
    let success = Color(hex: "#8FE432")
    let warning = Color(hex: "#F5D547")
    let error = Color(hex: "#FF8080")
    let background = Color(hex: "#1A1A2E")
    let surface = Color(hex: "#16213E")
    let textPrimary = Color(hex: "#E8E8E8")
    let textSecondary = Color(hex: "#A0A0A0")
}

// MARK: - Environment Key for Theme
struct ColorThemeKey: EnvironmentKey {
    static let defaultValue: ColorTheme = DefaultColorTheme()
}

extension EnvironmentValues {
    var colorTheme: ColorTheme {
        get { self[ColorThemeKey.self] }
        set { self[ColorThemeKey.self] = newValue }
    }
}
