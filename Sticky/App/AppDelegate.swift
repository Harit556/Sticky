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

    // MARK: - URL Scheme Handling (e.g. from Raycast)

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            // AppKit calls this on the main thread; hop to MainActor for Swift isolation
            Task { @MainActor in
                self.handleIncomingURL(url)
            }
        }
    }

    @MainActor
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "sticky", url.host == "add" else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let items = components?.queryItems else { return }

        var stickyID: UUID?
        var text: String?
        for item in items {
            if item.name == "stickyID", let v = item.value { stickyID = UUID(uuidString: v) }
            if item.name == "text",     let v = item.value { text = v }
        }

        guard let id = stickyID,
              let t = text,
              !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              var sticky = StickyStore.shared.sticky(for: id) else { return }

        // Add task and persist (this also schedules CloudKit push)
        sticky.addTask(title: t)
        StickyStore.shared.updateSticky(sticky)

        // Activate app and request SwiftUI to open the window.
        // Include a nonce so only one .onReceive handler reacts (every open
        // WindowGroup instance receives the notification; without dedupe we'd
        // open N duplicate windows).
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(
            name: .openStickyByID,
            object: nil,
            userInfo: ["stickyID": id, "nonce": UUID()]
        )
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

// MARK: - Notification Names

extension Notification.Name {
    static let openStickyByID = Notification.Name("OpenStickyByID")
}

/// Ensures only one `.onReceive` handler reacts per posted notification.
/// Multiple `StickyWindowRoot` views are alive when several stickies are open;
/// each receives every notification. We pin acting on it to the first handler
/// that grabs the nonce.
@MainActor
final class URLNotificationDeduper {
    static let shared = URLNotificationDeduper()
    private var processed: Set<UUID> = []

    func shouldProcess(_ nonce: UUID) -> Bool {
        if processed.contains(nonce) { return false }
        processed.insert(nonce)
        // Keep the set bounded; we never need more than the last few
        if processed.count > 64 { processed.removeAll() }
        return true
    }
}
