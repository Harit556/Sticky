import SwiftUI

struct StickyNoteView: View {
    @EnvironmentObject var store: StickyStore
    @Environment(\.colorScheme) var colorScheme

    let stickyID: UUID

    @StateObject private var soundManager = SoundManager.shared
    @State private var showColorPicker = false
    @State private var customColor: Color = .yellow

    private var sticky: Binding<StickyNote> {
        store.binding(for: stickyID)
    }

    var body: some View {
        let note = sticky.wrappedValue

        ZStack {
            // Full-bleed background color
            note.colorTheme.backgroundColor(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Thin header bar (just enough for native traffic light buttons)
                note.colorTheme.headerColor(for: colorScheme)
                    .frame(height: 2)

                // Editable title
                TextField("Title", text: sticky.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(note.colorTheme.textColor(for: colorScheme))
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                // Task list
                TodoListView(
                    sticky: sticky,
                    colorScheme: colorScheme,
                    onTaskCompleted: { taskID in
                        handleTaskCompletion(taskID: taskID)
                    }
                )

                Spacer(minLength: 0)
            }

            // Peel shadow in bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    PeelShadowView(colorScheme: colorScheme)
                }
            }
        }
        .frame(minWidth: 220, minHeight: 180)
        .contextMenu {
            colorContextMenu
        }
        .sheet(isPresented: $showColorPicker) {
            customColorPickerSheet
        }
        .onAppear {
            configureWindow()
        }
        .onChange(of: note.isAlwaysOnTop) { _, isOnTop in
            setWindowLevel(floating: isOnTop)
        }
    }

    // MARK: - Color Context Menu

    @ViewBuilder
    private var colorContextMenu: some View {
        Text("Theme").font(.headline)

        ForEach(PresetColor.allCases) { preset in
            Button(action: {
                sticky.wrappedValue.colorTheme = .preset(preset)
            }) {
                HStack {
                    Circle()
                        .fill(preset.lightBackground)
                        .frame(width: 12, height: 12)
                    Text(preset.displayName)
                    if case .preset(let current) = sticky.wrappedValue.colorTheme, current == preset {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }

        Divider()

        Button("Custom Color...") {
            if case .custom(let hex) = sticky.wrappedValue.colorTheme {
                customColor = Color(hex: hex)
            } else {
                customColor = sticky.wrappedValue.colorTheme.asColor
            }
            showColorPicker = true
        }

        Divider()

        Text("Sound Effect").font(.headline)

        ForEach(SoundEffect.presets) { sound in
            Button(action: {
                soundManager.selectedSound = sound
            }) {
                HStack {
                    Text(sound.displayName)
                    if soundManager.selectedSound == sound {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }

        Divider()

        if soundManager.selectedSound == .custom {
            Button("✓ Custom: \(soundManager.customSoundName)") {}
                .disabled(true)
        }

        Button("Upload Custom Sound...") {
            soundManager.importCustomSound()
        }
    }

    // MARK: - Custom Color Picker

    @ViewBuilder
    private var customColorPickerSheet: some View {
        VStack(spacing: 16) {
            Text("Choose Custom Color")
                .font(.headline)

            ColorPicker("Sticky Color", selection: $customColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 200)

            // Preview
            RoundedRectangle(cornerRadius: 8)
                .fill(customColor)
                .frame(width: 120, height: 80)
                .shadow(radius: 2)

            HStack {
                Button("Cancel") {
                    showColorPicker = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Apply") {
                    sticky.wrappedValue.colorTheme = .custom(customColor.hexString)
                    showColorPicker = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 260)
    }

    // MARK: - Window Management

    private func configureWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            guard let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first(where: { $0.isVisible }) else { return }

            let note = sticky.wrappedValue

            // Apply floating level
            window.level = note.isAlwaysOnTop ? .floating : .normal

            // Restore saved window frame
            if let frame = note.windowFrame {
                window.setFrame(frame.cgRect, display: true, animate: false)
            }
        }
    }

    private func setWindowLevel(floating: Bool) {
        NSApplication.shared.keyWindow?.level = floating ? .floating : .normal
    }

    // MARK: - Actions

    private func handleTaskCompletion(taskID: UUID) {
        // Capture values we need before dispatching
        let windowFrame = NSApplication.shared.keyWindow?.frame
        let task = sticky.wrappedValue.tasks.first(where: { $0.id == taskID })
        let stickyName = sticky.wrappedValue.colorTheme.displayName
        let sid = stickyID

        // Dispatch sound + confetti async so the checkbox animation isn't blocked
        DispatchQueue.main.async {
            SoundManager.shared.playCompletionSound()

            if let frame = windowFrame {
                let screenPoint = NSPoint(
                    x: frame.minX + 50,
                    y: frame.maxY - 60
                )
                ConfettiWindowController.shared.triggerConfetti(atScreenPoint: screenPoint)
            }

            // Fire Zapier webhook
            if let task = task {
                ZapierWebhookService.shared.fireEvent(
                    type: .taskCompleted,
                    stickyID: sid,
                    stickyName: stickyName,
                    task: task
                )
            }
        }
    }

}
