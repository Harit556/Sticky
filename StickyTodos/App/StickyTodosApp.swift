import SwiftUI

@main
struct StickyTodosApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = StickyStore.shared
    @Environment(\.openWindow) var openWindow

    var body: some Scene {
        // Main sticky note windows — each one gets a UUID to look up
        WindowGroup(id: "sticky", for: UUID.self) { $stickyID in
            StickyWindowRoot(stickyID: $stickyID)
                .environmentObject(store)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 280, height: 400)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Sticky Note") {
                    let note = store.createSticky()
                    openWindow(id: "sticky", value: note.id)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        // Settings window for Zapier
        Window("Zapier Integration", id: "zapier-settings") {
            ZapierSettingsView()
        }
        .windowResizability(.contentSize)

        // Menu bar extra
        MenuBarExtra("StickyTodos", systemImage: "note.text") {
            menuBarContent
        }
        .menuBarExtraStyle(.menu)
    }

    @ViewBuilder
    private var menuBarContent: some View {
        if store.stickies.isEmpty {
            Text("No stickies")
                .foregroundStyle(.secondary)
        } else {
            ForEach(store.stickies) { sticky in
                Button(action: {
                    openWindow(id: "sticky", value: sticky.id)
                }) {
                    HStack {
                        Circle()
                            .fill(sticky.colorTheme.swatchColor)
                            .frame(width: 8, height: 8)
                        Text("\(sticky.colorTheme.displayName) — \(sticky.remainingCount)/\(sticky.totalCount) tasks")
                    }
                }
            }
        }

        Divider()

        Button("New Sticky Note") {
            let note = store.createSticky()
            openWindow(id: "sticky", value: note.id)
        }
        .keyboardShortcut("n", modifiers: .command)

        Divider()

        Button("Zapier Integration...") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "zapier-settings")
        }

        Divider()

        Button("Quit StickyTodos") {
            store.saveToDisk()
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

// MARK: - Window Root
// Handles the case where SwiftUI opens the window with a nil UUID (first launch)

struct StickyWindowRoot: View {
    @Binding var stickyID: UUID?
    @EnvironmentObject var store: StickyStore

    var body: some View {
        Group {
            if let id = stickyID, store.sticky(for: id) != nil {
                StickyNoteView(stickyID: id)
            } else {
                // First launch or missing sticky — assign the first one
                Color.clear.onAppear {
                    if stickyID == nil || store.sticky(for: stickyID!) == nil {
                        let id = store.stickies.first?.id ?? store.createSticky().id
                        stickyID = id
                    }
                }
            }
        }
    }
}
