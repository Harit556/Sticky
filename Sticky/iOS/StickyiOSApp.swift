import SwiftUI

@main
struct StickyiOSApp: App {
    @StateObject private var store = StickyStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            iOSContentView()
                .environmentObject(store)
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        Task { await store.syncFromCloud() }
                    }
                }
        }
    }
}
