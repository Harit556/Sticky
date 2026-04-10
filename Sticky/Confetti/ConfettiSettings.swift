import AppKit

enum ConfettiSize: String, CaseIterable, Identifiable, Codable, Hashable {
    case small, medium, large
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var particleScale: CGFloat {
        switch self {
        case .small: return 0.7
        case .medium: return 1.2
        case .large: return 2.0
        }
    }

    var textureSize: CGSize {
        switch self {
        case .small: return CGSize(width: 5, height: 3)
        case .medium: return CGSize(width: 8, height: 5)
        case .large: return CGSize(width: 12, height: 7)
        }
    }
}

enum ConfettiAmount: String, CaseIterable, Identifiable, Codable, Hashable {
    case none, few, normal, lots
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .few: return "Few"
        case .normal: return "Normal"
        case .lots: return "Lots"
        }
    }

    var particleCount: Int {
        switch self {
        case .none: return 0
        case .few: return 40
        case .normal: return 100
        case .lots: return 250
        }
    }

    var birthRate: CGFloat {
        switch self {
        case .none: return 0
        case .few: return 150
        case .normal: return 300
        case .lots: return 600
        }
    }
}

enum ConfettiVolume: String, CaseIterable, Identifiable, Codable, Hashable {
    case off, low, medium, high
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var volume: Float {
        switch self {
        case .off: return 0.0
        case .low: return 0.3
        case .medium: return 0.7
        case .high: return 1.0
        }
    }
}

enum ConfettiGravity: String, CaseIterable, Identifiable, Codable, Hashable {
    case low, medium, high
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var yGravity: CGFloat {
        switch self {
        case .low: return -2.0
        case .medium: return -5.0
        case .high: return -9.8
        }
    }
}

enum ConfettiColorScheme: String, CaseIterable, Identifiable, Codable, Hashable {
    case rainbow, warm, cool, gold, pink
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rainbow: return "Rainbow"
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .gold: return "Gold"
        case .pink: return "Pink"
        }
    }

    var colors: [NSColor] {
        switch self {
        case .rainbow:
            return [
                NSColor(red: 1.0, green: 0.15, blue: 0.25, alpha: 1.0),
                NSColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0),
                NSColor(red: 0.15, green: 0.85, blue: 0.35, alpha: 1.0),
                NSColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0),
                NSColor(red: 0.85, green: 0.2, blue: 1.0, alpha: 1.0),
                NSColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1.0),
                NSColor(red: 0.0, green: 0.9, blue: 0.85, alpha: 1.0),
                NSColor(red: 1.0, green: 0.4, blue: 0.7, alpha: 1.0),
            ]
        case .warm:
            return [
                NSColor(red: 1.0, green: 0.15, blue: 0.15, alpha: 1.0),
                NSColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0),
                NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0),
                NSColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0),
                NSColor(red: 0.95, green: 0.3, blue: 0.2, alpha: 1.0),
                NSColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0),
            ]
        case .cool:
            return [
                NSColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0),
                NSColor(red: 0.4, green: 0.3, blue: 1.0, alpha: 1.0),
                NSColor(red: 0.0, green: 0.8, blue: 0.9, alpha: 1.0),
                NSColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 1.0),
                NSColor(red: 0.1, green: 0.6, blue: 0.9, alpha: 1.0),
                NSColor(red: 0.3, green: 0.9, blue: 0.8, alpha: 1.0),
            ]
        case .gold:
            return [
                NSColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
                NSColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0),
                NSColor(red: 1.0, green: 0.93, blue: 0.55, alpha: 1.0),
                NSColor(red: 0.72, green: 0.53, blue: 0.04, alpha: 1.0),
                NSColor(red: 1.0, green: 0.75, blue: 0.15, alpha: 1.0),
                NSColor(red: 0.9, green: 0.8, blue: 0.4, alpha: 1.0),
            ]
        case .pink:
            return [
                NSColor(red: 1.0, green: 0.4, blue: 0.7, alpha: 1.0),
                NSColor(red: 1.0, green: 0.2, blue: 0.5, alpha: 1.0),
                NSColor(red: 0.95, green: 0.55, blue: 0.8, alpha: 1.0),
                NSColor(red: 1.0, green: 0.3, blue: 0.6, alpha: 1.0),
                NSColor(red: 0.85, green: 0.15, blue: 0.55, alpha: 1.0),
                NSColor(red: 1.0, green: 0.6, blue: 0.85, alpha: 1.0),
            ]
        }
    }
}

@MainActor
class ConfettiSettings: ObservableObject {
    static let shared = ConfettiSettings()

    @Published var size: ConfettiSize {
        didSet { UserDefaults.standard.set(size.rawValue, forKey: "confettiSize") }
    }
    @Published var amount: ConfettiAmount {
        didSet { UserDefaults.standard.set(amount.rawValue, forKey: "confettiAmount") }
    }
    @Published var volume: ConfettiVolume {
        didSet { UserDefaults.standard.set(volume.rawValue, forKey: "confettiVolume") }
    }
    @Published var colorScheme: ConfettiColorScheme {
        didSet { UserDefaults.standard.set(colorScheme.rawValue, forKey: "confettiColorScheme") }
    }
    @Published var gravity: ConfettiGravity {
        didSet { UserDefaults.standard.set(gravity.rawValue, forKey: "confettiGravity") }
    }

    private init() {
        self.size = ConfettiSize(rawValue: UserDefaults.standard.string(forKey: "confettiSize") ?? "") ?? .medium
        self.amount = ConfettiAmount(rawValue: UserDefaults.standard.string(forKey: "confettiAmount") ?? "") ?? .normal
        self.volume = ConfettiVolume(rawValue: UserDefaults.standard.string(forKey: "confettiVolume") ?? "") ?? .medium
        self.colorScheme = ConfettiColorScheme(rawValue: UserDefaults.standard.string(forKey: "confettiColorScheme") ?? "") ?? .rainbow
        self.gravity = ConfettiGravity(rawValue: UserDefaults.standard.string(forKey: "confettiGravity") ?? "") ?? .medium
    }
}
