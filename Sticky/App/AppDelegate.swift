import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowObserver: Any?
    private var configuredWindows: Set<ObjectIdentifier> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Pre-warm confetti window and sound so first trigger is instant
        ConfettiWindowController.shared.warmUp()
        _ = SoundManager.shared  // Force singleton init, which pre-loads the sound
        GlobalHotkeyManager.shared.register()


        // Tell any open StickyNoteView to open remaining stickies
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            StickyStore.shared.openAllTrigger += 1
        }

        // Observe new windows to apply sticky styling
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            self?.configureStickyWindow(window)
        }

        // Also catch windows that become visible without becoming key
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeMainNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            self?.configureStickyWindow(window)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep alive for menu bar
    }


    private func configureStickyWindow(_ window: NSWindow) {
        let windowID = ObjectIdentifier(window)

        // Skip if already configured
        guard !configuredWindows.contains(windowID) else { return }

        // Skip system windows, panels, sheets, menus
        let className = String(describing: type(of: window))
        if className.contains("StatusBar") || className.contains("MenuBar") || className.contains("Panel") {
            return
        }

        // Only configure windows that belong to our "sticky" window group
        // SwiftUI-managed windows for our app
        guard window.styleMask.contains(.titled) else { return }

        configuredWindows.insert(windowID)

        // Apply sticky note styling
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.hasShadow = true

        // Clean up tracking when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            guard let closedWindow = notification.object as? NSWindow else { return }
            self?.configuredWindows.remove(ObjectIdentifier(closedWindow))
        }
    }
}
