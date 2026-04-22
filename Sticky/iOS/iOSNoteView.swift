import SwiftUI

struct iOSNoteView: View {
    @Binding var sticky: StickyNote
    @EnvironmentObject var store: StickyStore
    @Environment(\.colorScheme) var colorScheme

    @State private var showSettings = false
    @State private var newTaskText  = ""
    @FocusState private var newTaskFocused: Bool

    private var theme: StickyColorTheme { sticky.colorTheme }

    var sortedTasks: [TodoItem] {
        if sticky.autoSortCompleted {
            return sticky.tasks.sorted { !$0.isCompleted && $1.isCompleted }
        }
        return sticky.tasks.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ZStack(alignment: .top) {
            theme.backgroundColor(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                taskList
            }
        }
        .sheet(isPresented: $showSettings) {
            iOSSettingsView(sticky: $sticky)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            // New sticky button
            Button {
                let _ = store.createSticky()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.textColor(for: colorScheme).opacity(0.7))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            // Title
            TextField("Title", text: $sticky.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textColor(for: colorScheme))

            // Settings button
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.textColor(for: colorScheme).opacity(0.7))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(theme.headerColor(for: colorScheme).ignoresSafeArea(edges: .top))
    }

    // MARK: - Task List

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sortedTasks) { task in
                    if let binding = taskBinding(for: task.id) {
                        iOSTodoRow(
                            task: binding,
                            theme: theme,
                            colorScheme: colorScheme
                        ) {
                            withAnimation(.easeOut(duration: 0.15)) {
                                sticky.deleteTask(id: task.id)
                            }
                        }
                        Divider()
                            .foregroundStyle(theme.textColor(for: colorScheme).opacity(0.08))
                            .padding(.leading, 52)
                    }
                }

                // Add task row
                HStack(spacing: 12) {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.checkboxColor(for: colorScheme))
                        .frame(width: 28)

                    TextField("Add task...", text: $newTaskText, axis: .vertical)
                        .font(.system(size: 16))
                        .foregroundStyle(theme.textColor(for: colorScheme))
                        .focused($newTaskFocused)
                        .onSubmit {
                            commitNewTask()
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .padding(.bottom, 40) // room for TabView page dots
        }
    }

    private func taskBinding(for id: UUID) -> Binding<TodoItem>? {
        guard let index = sticky.tasks.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.sticky.tasks[index] },
            set: { self.sticky.tasks[index] = $0 }
        )
    }

    private func commitNewTask() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        sticky.addTask(title: trimmed)
        newTaskText = ""
    }
}
