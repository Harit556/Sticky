import AppKit
import AVFoundation

enum SoundEffect: String, CaseIterable, Identifiable, Codable {
    case confetti = "confetti"
    case yay = "Yay"
    case yippie = "Yippie"
    case catLaugh = "Cat Laugh"
    case applePay = "Apple Pay"
    case rizz = "Rizz"
    case custom = "__custom__"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .confetti: return "🎉 Confetti"
        case .yay: return "🥳 Yay"
        case .yippie: return "🎊 Yippie"
        case .catLaugh: return "😹 Cat Laugh"
        case .applePay: return "💳 Apple Pay"
        case .rizz: return "😎 Rizz"
        case .custom: return "📁 Custom..."
        }
    }

    /// The built-in presets (everything except custom)
    static var presets: [SoundEffect] {
        allCases.filter { $0 != .custom }
    }
}

@MainActor
class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @Published var selectedSound: SoundEffect {
        didSet {
            UserDefaults.standard.set(selectedSound.rawValue, forKey: "selectedSound")
            loadCurrentSound()
        }
    }

    @Published var customSoundURL: URL? {
        didSet {
            if let url = customSoundURL {
                // Bookmark the URL so we can access it after app restart
                if let bookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                    UserDefaults.standard.set(bookmark, forKey: "customSoundBookmark")
                }
                UserDefaults.standard.set(url.lastPathComponent, forKey: "customSoundName")
            }
            if selectedSound == .custom {
                loadCurrentSound()
            }
        }
    }

    var customSoundName: String {
        UserDefaults.standard.string(forKey: "customSoundName") ?? "None"
    }

    private var player: AVAudioPlayer?

    private init() {
        // Restore saved selection
        let savedKey = UserDefaults.standard.string(forKey: "selectedSound") ?? SoundEffect.confetti.rawValue
        self.selectedSound = SoundEffect(rawValue: savedKey) ?? .confetti

        // Restore custom sound bookmark
        if let bookmarkData = UserDefaults.standard.data(forKey: "customSoundBookmark") {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                self.customSoundURL = url
            }
        }

        loadCurrentSound()
    }

    func playCompletionSound() {
        if let player = player {
            if player.isPlaying {
                player.stop()
            }
            player.currentTime = 0
            player.volume = 0.7
            player.play()
        }
    }

    /// Preview a specific sound effect
    func previewSound(_ sound: SoundEffect) {
        let previousSound = selectedSound
        let url = soundURL(for: sound)
        if let url = url, let previewPlayer = try? AVAudioPlayer(contentsOf: url) {
            // Stop current playback
            player?.stop()
            // Play preview
            previewPlayer.volume = 0.7
            previewPlayer.play()
            // Keep reference so it doesn't get deallocated
            player = previewPlayer
            // Restore original sound after preview
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if self?.selectedSound == previousSound {
                    self?.loadCurrentSound()
                }
            }
        }
    }

    private func loadCurrentSound() {
        guard let url = soundURL(for: selectedSound) else {
            player = nil
            return
        }

        if selectedSound == .custom {
            // Start security-scoped access for sandboxed apps
            _ = url.startAccessingSecurityScopedResource()
        }

        player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
    }

    private func soundURL(for sound: SoundEffect) -> URL? {
        switch sound {
        case .custom:
            return customSoundURL
        default:
            return Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3")
        }
    }

    // MARK: - Custom Sound Import

    func importCustomSound() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Sound Effect"
        panel.allowedContentTypes = [.mp3, .wav, .aiff, .audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            customSoundURL = url
            selectedSound = .custom
        }
    }
}
