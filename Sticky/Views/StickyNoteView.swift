import SwiftUI

struct StickyNoteView: View {
    @EnvironmentObject var store: StickyStore
    @Environment(\.colorScheme) var colorScheme

    let stickyID: UUID

    @Environment(\.openWindow) private var openWindow
    @State private var showSettings = false

    private var sticky: Binding<StickyNote> {
        store.binding(for: stickyID)
    }

    var body: some View {
        let note = sticky.wrappedValue

        ZStack {
            note.colorTheme.backgroundColor(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                note.colorTheme.headerColor(for: colorScheme)
                    .frame(height: 2)

                TextField("Title", text: sticky.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(note.colorTheme.textColor(for: colorScheme))
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                TodoListView(
                    sticky: sticky,
                    colorScheme: colorScheme,
                    onTaskCompleted: { taskID in handleTaskCompletion(taskID: taskID) }
                )

                Spacer(minLength: 0)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    PeelShadowView(colorScheme: colorScheme) {
                        createNoteNextToCurrentWindow()
                    }
                }
            }
        }
        .frame(minWidth: 220, minHeight: 180)
        // Right-click anywhere on the sticky opens settings
        .overlay(RightClickHandler { showSettings = true })
        .popover(isPresented: $showSettings, arrowEdge: .trailing) {
            SettingsPanelView(
                sticky: sticky,
                colorScheme: colorScheme,
                onTestConfetti: { fireTestConfetti() },
                onDeleteNote: { deleteCurrentNote() }
            )
        }
        .onChange(of: showSettings) { _, isShowing in
            if isShowing {
                // Elevate the popover window above all stickies
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    for window in NSApplication.shared.windows where window.isVisible {
                        let name = String(describing: type(of: window))
                        if name.contains("Popover") {
                            window.level = NSWindow.Level(Int(CGShieldingWindowLevel()))
                        }
                    }
                }
            }
        }
        .onAppear {
            configureWindow()
            openFirstLaunchStickies()
        }
        .onChange(of: note.isAlwaysOnTop) { _, isOnTop in setWindowLevel(floating: isOnTop) }
    }

    // MARK: - Window Management

    private func configureWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            guard let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first(where: { $0.isVisible }) else { return }
            let note = sticky.wrappedValue
            window.level = note.isAlwaysOnTop ? .floating : .normal
            if let frame = note.windowFrame {
                window.setFrame(frame.cgRect, display: true, animate: false)
            }
        }

    }

    private func openFirstLaunchStickies() {
        guard store.isFirstLaunch else { return }
        store.isFirstLaunch = false
        let currentID = stickyID
        let otherStickies = store.stickies.filter { $0.id != currentID }
        for (index, other) in otherStickies.enumerated() {
            let delay = 0.8 + Double(index) * 0.4
            let id = other.id
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NSLog("STICKY: Opening window for \(id)")
                self.openWindow(id: "sticky", value: id)
            }
        }
    }

    private func setWindowLevel(floating: Bool) {
        NSApplication.shared.keyWindow?.level = floating ? .floating : .normal
    }

    private func createNoteNextToCurrentWindow() {
        let currentFrame = NSApplication.shared.keyWindow?.frame
        let note = store.createSticky(nextToFrame: currentFrame)
        openWindow(id: "sticky", value: note.id)
    }

    private func deleteCurrentNote() {
        showSettings = false
        // Close this window then delete the note
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApplication.shared.keyWindow?.close()
            store.deleteSticky(id: stickyID)
        }
    }

    // MARK: - Actions

    private func fireTestConfetti() {
        let windowFrame = NSApplication.shared.keyWindow?.frame
        let note = sticky.wrappedValue
        DispatchQueue.main.async {
            SoundManager.shared.playCompletionSound(sound: note.soundEffect, volume: note.confettiVolume)
            if let frame = windowFrame {
                ConfettiWindowController.shared.triggerConfetti(
                    atScreenPoint: NSPoint(x: frame.minX + 50, y: frame.maxY - 60),
                    size: note.confettiSize,
                    amount: note.confettiAmount,
                    gravity: note.confettiGravity,
                    colorScheme: note.confettiColorScheme
                )
            }
        }
    }

    private func handleTaskCompletion(taskID: UUID) {
        let windowFrame = NSApplication.shared.keyWindow?.frame
        let note = sticky.wrappedValue
        let task = note.tasks.first(where: { $0.id == taskID })
        let stickyName = note.colorTheme.displayName
        let sid = stickyID

        DispatchQueue.main.async {
            SoundManager.shared.playCompletionSound(sound: note.soundEffect, volume: note.confettiVolume)
            if let frame = windowFrame {
                ConfettiWindowController.shared.triggerConfetti(
                    atScreenPoint: NSPoint(x: frame.minX + 50, y: frame.maxY - 60),
                    size: note.confettiSize,
                    amount: note.confettiAmount,
                    gravity: note.confettiGravity,
                    colorScheme: note.confettiColorScheme
                )
            }
            if let task = task {
                ZapierWebhookService.shared.fireEvent(type: .taskCompleted, stickyID: sid, stickyName: stickyName, task: task)
            }
        }
    }
}
