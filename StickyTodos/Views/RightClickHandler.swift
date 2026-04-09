import SwiftUI
import AppKit

/// Invisible overlay that intercepts ONLY right-clicks and passes everything else through.
struct RightClickHandler: NSViewRepresentable {
    var onRightClick: () -> Void

    func makeNSView(context: Context) -> RightClickView {
        let view = RightClickView()
        view.onRightClick = onRightClick
        return view
    }

    func updateNSView(_ view: RightClickView, context: Context) {
        view.onRightClick = onRightClick
    }

    class RightClickView: NSView {
        var onRightClick: (() -> Void)?

        override func hitTest(_ point: NSPoint) -> NSView? {
            // Only claim the hit for right-click events.
            // Everything else (left-click, drag, scroll, hover) passes straight through.
            if NSApp.currentEvent?.type == .rightMouseDown {
                return super.hitTest(point)
            }
            return nil
        }

        override func rightMouseDown(with event: NSEvent) {
            onRightClick?()
        }
    }
}
