import AppKit
import SpriteKit

/// A transparent fullscreen window that displays confetti over the entire screen.
/// Pre-created at launch to avoid lag on first confetti trigger.
class ConfettiWindowController {
    static let shared = ConfettiWindowController()

    private var window: NSWindow?
    private var scene: ConfettiScene?

    private init() {}

    /// Call once at app launch to pre-create the window so first confetti is instant.
    func warmUp() {
        ensureWindow()
        // Hide it immediately — it's ready but invisible
        window?.orderOut(nil)
    }

    /// Trigger a confetti burst at the given screen coordinate (origin bottom-left).
    func triggerConfetti(atScreenPoint point: NSPoint) {
        ensureWindow()
        window?.orderFrontRegardless()
        scene?.triggerConfettiDirect(at: CGPoint(x: point.x, y: point.y))

        // Auto-hide after particles finish
        scheduleHide()
    }

    private var hideTimer: Timer?

    private func scheduleHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            if let scene = self?.scene, scene.children.isEmpty {
                self?.window?.orderOut(nil)
            }
        }
    }

    private func ensureWindow() {
        if window != nil { return }

        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame

        let win = NSWindow(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.level = .floating + 1
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .transient]

        let confettiScene = ConfettiScene()
        confettiScene.size = screenFrame.size
        confettiScene.scaleMode = .resizeFill
        confettiScene.backgroundColor = .clear

        let skView = SKView(frame: screenFrame)
        skView.allowsTransparency = true
        skView.presentScene(confettiScene)

        win.contentView = skView

        self.window = win
        self.scene = confettiScene
    }
}
