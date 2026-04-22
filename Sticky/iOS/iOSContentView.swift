import SwiftUI

struct iOSContentView: View {
    @EnvironmentObject var store: StickyStore
    @State private var selectedIndex = 0

    var body: some View {
        if store.stickies.isEmpty {
            emptyState
        } else {
            TabView(selection: $selectedIndex) {
                ForEach(Array(store.stickies.enumerated()), id: \.element.id) { index, sticky in
                    iOSNoteView(sticky: store.binding(for: sticky.id))
                        .tag(index)
                        .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .ignoresSafeArea()
            .onChange(of: store.stickies.count) { count in
                // Keep selection in bounds
                if selectedIndex >= count {
                    selectedIndex = max(0, count - 1)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("📝").font(.system(size: 60))
            Text("No stickies yet").font(.title2.bold())
            Button {
                let _ = store.createSticky()
            } label: {
                Label("New Sticky", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }
}
