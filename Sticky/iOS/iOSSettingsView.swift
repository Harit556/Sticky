import SwiftUI

struct iOSSettingsView: View {
    @Binding var sticky: StickyNote
    @EnvironmentObject var store: StickyStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Theme
                Section("Theme") {
                    ForEach(PresetColor.allCases) { preset in
                        Button {
                            sticky.colorTheme = .preset(preset)
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(preset.lightBackground)
                                    .frame(width: 28, height: 28)
                                Text(preset.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if case .preset(let c) = sticky.colorTheme, c == preset {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                // MARK: Sound
                Section("Sound Effect") {
                    Picker("Sound", selection: Binding(
                        get: { sticky.soundEffect ?? SoundManager.shared.selectedSound },
                        set: { sticky.soundEffect = $0 }
                    )) {
                        ForEach(SoundEffect.presets) { sound in
                            Text(sound.displayName).tag(sound)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: Confetti
                Section("Confetti") {
                    Picker("Style", selection: Binding(
                        get: { sticky.confettiStyle ?? ConfettiSettings.shared.style },
                        set: { sticky.confettiStyle = $0 }
                    )) {
                        ForEach(ConfettiStyle.allCases) { Text($0.displayName).tag($0) }
                    }

                    Picker("Amount", selection: Binding(
                        get: { sticky.confettiAmount ?? ConfettiSettings.shared.amount },
                        set: { sticky.confettiAmount = $0 }
                    )) {
                        ForEach(ConfettiAmount.allCases) { Text($0.displayName).tag($0) }
                    }

                    Picker("Colour", selection: Binding(
                        get: { sticky.confettiColorScheme ?? ConfettiSettings.shared.colorScheme },
                        set: { sticky.confettiColorScheme = $0 }
                    )) {
                        ForEach(ConfettiColorScheme.allCases) { Text($0.displayName).tag($0) }
                    }
                }

                // MARK: Options
                Section("Options") {
                    Toggle("Sort completed to bottom", isOn: $sticky.autoSortCompleted)
                }

                // MARK: Danger zone
                Section {
                    Button("Duplicate This Note") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            store.duplicateSticky(id: sticky.id)
                        }
                    }

                    Button("Delete This Note", role: .destructive) {
                        let id = sticky.id
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            store.deleteSticky(id: id)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
