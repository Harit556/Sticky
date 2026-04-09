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

            CommandMenu("Notes") {
                ForEach(store.stickies) { sticky in
                    Menu("\(sticky.title) — \(sticky.remainingCount)/\(sticky.totalCount)") {
                        Button("Open") {
                            openWindow(id: "sticky", value: sticky.id)
                        }
                        Button("Delete") {
                            store.deleteSticky(id: sticky.id)
                        }
                    }
                }

                Divider()

                Button("New Sticky Note") {
                    let note = store.createSticky()
                    openWindow(id: "sticky", value: note.id)
                }

                Divider()

                Button("Zapier Integration...") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "zapier-settings")
                }
            }
        }

        // Settings window for Zapier
        Window("Zapier Integration", id: "zapier-settings") {
            ZapierSettingsView()
        }
        .windowResizability(.contentSize)
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
