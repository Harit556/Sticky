import SwiftUI
import AppKit

/// Custom NSTextField subclass that intercepts CMD+Enter via performKeyEquivalent,
/// which is more reliable than doCommandBy for modifier+key combos.
class TaskTextField: NSTextField {
    var onCmdReturn: (() -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // keyCode 36 = Return/Enter
        if event.keyCode == 36,
           event.modifierFlags.contains(.command),
           let editor = currentEditor(), window?.firstResponder == editor {
            onCmdReturn?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

/// A TextField that detects backspace on an empty field, Enter key, CMD+Enter, and arrow keys.
struct BackspaceTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = "New task..."
    var font: NSFont = .systemFont(ofSize: 13)
    var textColor: NSColor = .labelColor
    var onBackspaceEmpty: () -> Void
    var onSubmit: () -> Void
    var onCmdEnter: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    var focusToken: UUID?
    var onFocusGranted: () -> Void

    func makeNSView(context: Context) -> TaskTextField {
        let textField = TaskTextField()
        textField.onCmdReturn = onCmdEnter
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

    func updateNSView(_ textField: TaskTextField, context: Context) {
        context.coordinator.onBackspaceEmpty = onBackspaceEmpty
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onMoveUp = onMoveUp
        context.coordinator.onMoveDown = onMoveDown
        context.coordinator.onFocusGranted = onFocusGranted
        context.coordinator.textBinding = $text
        textField.onCmdReturn = onCmdEnter

        if textField.stringValue != text {
            textField.stringValue = text
        }
        textField.font = font
        textField.textColor = textColor
        textField.placeholderString = placeholder

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

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                onSubmit()
                return true
            }
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                if textView.string.isEmpty {
                    onBackspaceEmpty()
                    return true
                }
            }
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
