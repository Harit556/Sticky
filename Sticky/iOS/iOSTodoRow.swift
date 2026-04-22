import SwiftUI

struct iOSTodoRow: View {
    @Binding var task: TodoItem
    let theme: StickyColorTheme
    let colorScheme: ColorScheme
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    task.isCompleted.toggle()
                }
                // Light haptic on toggle
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        task.isCompleted
                            ? Color.green.opacity(0.8)
                            : theme.checkboxColor(for: colorScheme)
                    )
                    .frame(width: 28)
            }
            .buttonStyle(.plain)

            TextField("Task", text: $task.title, axis: .vertical)
                .font(.system(size: 16))
                .foregroundStyle(
                    task.isCompleted
                        ? theme.secondaryTextColor(for: colorScheme)
                        : theme.textColor(for: colorScheme)
                )
                .strikethrough(task.isCompleted, color: theme.secondaryTextColor(for: colorScheme))
                .lineLimit(1...8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
