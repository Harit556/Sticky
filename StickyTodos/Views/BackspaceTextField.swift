import SwiftUI
import AppKit

/// A TextField that detects backspace on an empty field, Enter key, and arrow keys.
struct BackspaceTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = "New task..."
    var font: NSFont = .systemFont(ofSize: 13)
    var textColor: NSColor = .labelColor
    var onBackspaceEmpty: () -> Void
    var onSubmit: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    var focusToken: UUID?        // The token that requests focus
    var onFocusGranted: () -> Void  // Called once focus is established (to clear the token)

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.stringValue = text
        textField.placeholderString = placeholder
        textField.font = font
        textField.textColor = textColor
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.lineBreakMode = .byTruncatingTail
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        // Update callbacks
        context.coordinator.onBackspaceEmpty = onBackspaceEmpty
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onMoveUp = onMoveUp
        context.coordinator.onMoveDown = onMoveDown
        context.coordinator.onFocusGranted = onFocusGranted
        context.coordinator.textBinding = $text

        // Update text only if different (avoid cursor jump)
        if textField.stringValue != text {
            textField.stringValue = text
        }

        textField.font = font
        textField.textColor = textColor
        textField.placeholderString = placeholder

        // Handle focus requests — only act when the token CHANGES
        let currentToken = focusToken
        if let token = currentToken, token != context.coordinator.lastProcessedFocusToken {
            context.coordinator.lastProcessedFocusToken = token
            DispatchQueue.main.async {
                if let window = textField.window, textField.acceptsFirstResponder {
                    window.makeFirstResponder(textField)
                    onFocusGranted()
                }
            }
        }
        // If token was cleared (nil), reset so the same token can be used again later
        if currentToken == nil {
            context.coordinator.lastProcessedFocusToken = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            textBinding: $text,
            onBackspaceEmpty: onBackspaceEmpty,
            onSubmit: onSubmit,
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown,
            onFocusGranted: onFocusGranted
        )
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var textBinding: Binding<String>
        var onBackspaceEmpty: () -> Void
        var onSubmit: () -> Void
        var onMoveUp: () -> Void
        var onMoveDown: () -> Void
        var onFocusGranted: () -> Void

        /// Tracks the last focus token we already processed, so we don't re-focus on every update.
        var lastProcessedFocusToken: UUID?

        init(textBinding: Binding<String>,
             onBackspaceEmpty: @escaping () -> Void,
             onSubmit: @escaping () -> Void,
             onMoveUp: @escaping () -> Void,
             onMoveDown: @escaping () -> Void,
             onFocusGranted: @escaping () -> Void) {
            self.textBinding = textBinding
            self.onBackspaceEmpty = onBackspaceEmpty
            self.onSubmit = onSubmit
            self.onMoveUp = onMoveUp
            self.onMoveDown = onMoveDown
            self.onFocusGranted = onFocusGranted
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            textBinding.wrappedValue = textField.stringValue
        }

        // Intercepts commands from the field editor
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                onSubmit()
                return true
            }

            // deleteBackward: is what macOS sends for the Backspace key
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                if textView.string.isEmpty {
                    onBackspaceEmpty()
                    return true
                }
            }

            // Arrow key navigation between tasks
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                onMoveUp()
                return true
            }

            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                onMoveDown()
                return true
            }

            return false
        }

        func controlTextDidBeginEditing(_ obj: Notification) {}
        func controlTextDidEndEditing(_ obj: Notification) {}
    }
}
