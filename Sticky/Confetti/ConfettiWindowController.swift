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
    @MainActor
    func triggerConfetti(
        atScreenPoint point: NSPoint,
        size: ConfettiSize? = nil,
        amount: ConfettiAmount? = nil,
        gravity: ConfettiGravity? = nil,
        colorScheme: ConfettiColorScheme? = nil
    ) {
        ensureWindow()
        window?.orderFrontRegardless()
        scene?.triggerConfettiDirect(at: CGPoint(x: point.x, y: point.y), size: size, amount: amount, gravity: gravity, colorScheme: colorScheme)

        // Auto-hide after particles settle and fade (3s pile + 1s fade buffer)
        scheduleHide()
    }

    private var hideTimer: Timer?

    private func scheduleHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            // Only hide if no confetti nodes remain
            if let scene = self?.scene, scene.children.filter({ $0.name == "confetti" }).isEmpty {
                self?.window?.orderOut(nil)
            } else {
                // Check again in a second
                self?.scheduleHide()
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
        win.isReleasedWhenClosed = false
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

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: win,
            queue: .main
        ) { [weak self] _ in
            self?.window = nil
            self?.scene = nil
        }
    }
}
