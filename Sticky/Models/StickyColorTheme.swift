import SwiftUI

enum PresetColor: String, Codable, CaseIterable, Identifiable {
    case yellow, pink, green, blue, purple, orange

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var lightBackground: Color {
        switch self {
        case .yellow: return Color(red: 0.99, green: 0.98, blue: 0.70)
        case .pink:   return Color(red: 1.00, green: 0.82, blue: 0.86)
        case .green:  return Color(red: 0.78, green: 0.95, blue: 0.78)
        case .blue:   return Color(red: 0.78, green: 0.88, blue: 1.00)
        case .purple: return Color(red: 0.88, green: 0.80, blue: 1.00)
        case .orange: return Color(red: 1.00, green: 0.88, blue: 0.70)
        }
    }

    var darkBackground: Color {
        switch self {
        case .yellow: return Color(red: 0.45, green: 0.43, blue: 0.20)
        case .pink:   return Color(red: 0.50, green: 0.28, blue: 0.32)
        case .green:  return Color(red: 0.25, green: 0.40, blue: 0.25)
        case .blue:   return Color(red: 0.25, green: 0.32, blue: 0.45)
        case .purple: return Color(red: 0.35, green: 0.28, blue: 0.48)
        case .orange: return Color(red: 0.48, green: 0.35, blue: 0.20)
        }
    }

    var headerLight: Color {
        switch self {
        case .yellow: return Color(red: 0.95, green: 0.93, blue: 0.55)
        case .pink:   return Color(red: 0.95, green: 0.70, blue: 0.76)
        case .green:  return Color(red: 0.65, green: 0.88, blue: 0.65)
        case .blue:   return Color(red: 0.65, green: 0.78, blue: 0.95)
        case .purple: return Color(red: 0.78, green: 0.68, blue: 0.95)
        case .orange: return Color(red: 0.95, green: 0.78, blue: 0.55)
        }
    }

    var headerDark: Color {
        switch self {
        case .yellow: return Color(red: 0.38, green: 0.36, blue: 0.15)
        case .pink:   return Color(red: 0.42, green: 0.22, blue: 0.26)
        case .green:  return Color(red: 0.20, green: 0.33, blue: 0.20)
        case .blue:   return Color(red: 0.20, green: 0.26, blue: 0.38)
        case .purple: return Color(red: 0.28, green: 0.22, blue: 0.40)
        case .orange: return Color(red: 0.40, green: 0.28, blue: 0.15)
        }
    }

    var swatchColor: Color { lightBackground }
}

enum StickyColorTheme: Codable, Hashable, Equatable {
    case preset(PresetColor)
    case custom(String) // hex string like "#FF8800"

    static let defaultTheme: StickyColorTheme = .preset(.yellow)

    var backgroundColor: Color {
        colorSchemeAware(light: lightBackgroundColor, dark: darkBackgroundColor)
    }

    private var lightBackgroundColor: Color {
        switch self {
        case .preset(let color): return color.lightBackground
        case .custom(let hex): return Color(hex: hex)
        }
    }

    private var darkBackgroundColor: Color {
        switch self {
        case .preset(let color): return color.darkBackground
        case .custom(let hex): return Color(hex: hex).darkened(by: 0.4)
        }
    }

    var headerColor: Color {
        colorSchemeAware(light: lightHeaderColor, dark: darkHeaderColor)
    }

    private var lightHeaderColor: Color {
        switch self {
        case .preset(let color): return color.headerLight
        case .custom(let hex): return Color(hex: hex).darkened(by: 0.08)
        }
    }

    private var darkHeaderColor: Color {
        switch self {
        case .preset(let color): return color.headerDark
        case .custom(let hex): return Color(hex: hex).darkened(by: 0.5)
        }
    }

    var textColor: Color {
        colorSchemeAware(light: .black.opacity(0.85), dark: .white.opacity(0.9))
    }

    var secondaryTextColor: Color {
        colorSchemeAware(light: .black.opacity(0.4), dark: .white.opacity(0.4))
    }

    var checkboxColor: Color {
        colorSchemeAware(light: .black.opacity(0.6), dark: .white.opacity(0.6))
    }

    private func colorSchemeAware(light: Color, dark: Color) -> Color {
        // We'll resolve this at the view level using @Environment(\.colorScheme)
        // Return light as default; views will choose appropriately
        return light
    }

    func backgroundColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkBackgroundColor : lightBackgroundColor
    }

    func headerColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkHeaderColor : lightHeaderColor
    }

    func textColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.85)
    }

    func secondaryTextColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4)
    }

    func checkboxColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)
    }

    var displayName: String {
        switch self {
        case .preset(let color): return color.displayName
        case .custom: return "Custom"
        }
    }

    var swatchColor: Color {
        switch self {
        case .preset(let color): return color.swatchColor
        case .custom(let hex): return Color(hex: hex)
        }
    }

    // Convert custom color to/from SwiftUI Color for ColorPicker
    var asColor: Color {
        switch self {
        case .preset(let color): return color.lightBackground
        case .custom(let hex): return Color(hex: hex)
        }
    }
}

// MARK: - Color Hex Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func darkened(by amount: Double) -> Color {
        let nsColor = NSColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let converted = nsColor.usingColorSpace(.sRGB) ?? nsColor
        converted.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: Double(s), brightness: Double(max(b - CGFloat(amount), 0.05)), opacity: Double(a))
    }

    var hexString: String {
        let nsColor = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = Int(nsColor.redComponent * 255)
        let g = Int(nsColor.greenComponent * 255)
        let b = Int(nsColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
