import SwiftUI

struct TaskCountBadgeView: View {
    let remaining: Int
    let total: Int
    let colorScheme: ColorScheme

    var body: some View {
        if total > 0 {
            Text("\(remaining)/\(total)")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.5))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08))
                )
        }
    }
}
