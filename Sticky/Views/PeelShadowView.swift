import SwiftUI

struct PeelShadowView: View {
    let colorScheme: ColorScheme
    var onTap: (() -> Void)? = nil

    @State private var isHovering = false

    // 20% smaller than original (was 28/36)
    private var peelSize: CGFloat {
        isHovering ? 29 : 22
    }

    var body: some View {
        Canvas { context, size in
            let ps = peelSize
            let origin = CGPoint(x: size.width - ps, y: size.height - ps)

            // The fold triangle (lighter area showing "underside")
            var foldPath = Path()
            foldPath.move(to: CGPoint(x: size.width, y: size.height - ps))
            foldPath.addLine(to: CGPoint(x: size.width - ps, y: size.height))
            foldPath.addLine(to: CGPoint(x: size.width, y: size.height))
            foldPath.closeSubpath()

            let foldColor = colorScheme == .dark
                ? Color.black.opacity(0.3)
                : Color.black.opacity(0.08)

            context.fill(foldPath, with: .color(foldColor))

            // Curved shadow under the fold
            var shadowPath = Path()
            shadowPath.move(to: CGPoint(x: size.width, y: size.height - ps))
            shadowPath.addQuadCurve(
                to: CGPoint(x: size.width - ps, y: size.height),
                control: CGPoint(x: origin.x + 6, y: origin.y + 6)
            )
            shadowPath.addLine(to: CGPoint(x: size.width, y: size.height))
            shadowPath.closeSubpath()

            let shadowColor = colorScheme == .dark
                ? Color.black.opacity(0.5)
                : Color.black.opacity(0.15)

            context.fill(shadowPath, with: .color(shadowColor))
        }
        .frame(width: peelSize + 4, height: peelSize + 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.25)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onTap?()
        }
        .help("New sticky note")
    }
}
