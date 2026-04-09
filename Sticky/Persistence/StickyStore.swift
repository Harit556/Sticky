import Foundation
import SwiftUI

@MainActor
class StickyStore: ObservableObject {
    @Published var stickies: [StickyNote] = []
    var isFirstLaunch: Bool = false
    /// True only until the first StickyNoteView.onAppear has opened all windows this session.
    var hasOpenedAllOnLaunch: Bool = false

    private let fileURL: URL
    private var saveTask: Task<Void, Never>?

    static let shared = StickyStore()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Sticky", isDirectory: true)

        if !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        }

        self.fileURL = appDir.appendingPathComponent("stickies.json")
        self.stickies = loadFromDisk()

        if stickies.isEmpty {
            let noteWidth = 280.0
            let noteHeight = 400.0
            let gap = 12.0

            // Start roughly centred on screen
            let screenWidth = Double(NSScreen.main?.frame.width ?? 1440)
            let screenHeight = Double(NSScreen.main?.frame.height ?? 900)
            let totalWidth = noteWidth * 3 + gap * 2
            let startX = (screenWidth - totalWidth) / 2
            let startY = (screenHeight - noteHeight) / 2

            let welcomeNotes: [(title: String, task: String, theme: StickyColorTheme)] = [
                ("My Tasks",   "You can do it",               .preset(.yellow)),
                ("Shortcuts",  "CMD + Enter for ticking",     .preset(.green)),
                ("Tips",       "Right click for settings", .preset(.blue)),
            ]

            for (i, info) in welcomeNotes.enumerated() {
                var note = StickyNote(
                    title: info.title,
                    colorTheme: info.theme,
                    windowFrame: CodableRect(
                        x: startX + Double(i) * (noteWidth + gap),
                        y: startY,
                        width: noteWidth,
                        height: noteHeight
                    )
                )
                note.addTask(title: info.task)
                stickies.append(note)
            }

            saveToDisk()
            isFirstLaunch = true
        }
    }

    // MARK: - CRUD Operations

    @discardableResult
    func createSticky(nextToFrame frame: CGRect? = nil) -> StickyNote {
        var note = StickyNote()
        note.addTask(title: "You can do it")
        if let frame = frame {
            // Position the new note to the right of the triggering window, at the same vertical level
            note.windowFrame = CodableRect(
                x: Double(frame.maxX + 12),
                y: Double(frame.minY),
                width: 280,
                height: 400
            )
        }
        stickies.append(note)
        scheduleSave()
        return note
    }

    func deleteSticky(id: UUID) {
        stickies.removeAll { $0.id == id }
        scheduleSave()
    }

    func updateSticky(_ sticky: StickyNote) {
        if let index = stickies.firstIndex(where: { $0.id == sticky.id }) {
            stickies[index] = sticky
            scheduleSave()
        }
    }

    func sticky(for id: UUID) -> StickyNote? {
        stickies.first { $0.id == id }
    }

    func binding(for id: UUID) -> Binding<StickyNote> {
        Binding(
            get: { [weak self] in
                self?.stickies.first { $0.id == id } ?? StickyNote(id: id)
            },
            set: { [weak self] newValue in
                if let index = self?.stickies.firstIndex(where: { $0.id == id }) {
                    self?.stickies[index] = newValue
                    self?.scheduleSave()
                }
            }
        )
    }

    func resetToFirstLaunch() {
        stickies.removeAll()
        // Re-run the welcome note creation logic
        let noteWidth = 280.0
        let noteHeight = 400.0
        let gap = 12.0
        let screenWidth = Double(NSScreen.main?.frame.width ?? 1440)
        let screenHeight = Double(NSScreen.main?.frame.height ?? 900)
        let totalWidth = noteWidth * 3 + gap * 2
        let startX = (screenWidth - totalWidth) / 2
        let startY = (screenHeight - noteHeight) / 2

        let welcomeNotes: [(title: String, task: String, theme: StickyColorTheme)] = [
            ("My Tasks",   "You can do it",               .preset(.yellow)),
            ("Shortcuts",  "CMD + Enter for ticking",     .preset(.green)),
            ("Tips",       "Right click for settings",    .preset(.blue)),
        ]

        for (i, info) in welcomeNotes.enumerated() {
            var note = StickyNote(
                title: info.title,
                colorTheme: info.theme,
                windowFrame: CodableRect(
                    x: startX + Double(i) * (noteWidth + gap),
                    y: startY,
                    width: noteWidth,
                    height: noteHeight
                )
            )
            note.addTask(title: info.task)
            stickies.append(note)
        }

        // Reset global settings
        ConfettiSettings.shared.size = .medium
        ConfettiSettings.shared.amount = .normal
        ConfettiSettings.shared.gravity = .medium
        ConfettiSettings.shared.volume = .medium
        ConfettiSettings.shared.colorScheme = .rainbow

        saveToDisk()
    }

    // MARK: - Window Frame Persistence

    func updateWindowFrame(for stickyID: UUID, frame: CGRect) {
        if let index = stickies.firstIndex(where: { $0.id == stickyID }) {
            stickies[index].windowFrame = CodableRect(from: frame)
            scheduleSave()
        }
    }

    // MARK: - Persistence

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s debounce
            if !Task.isCancelled {
                saveToDisk()
            }
        }
    }

    func saveToDisk() {
        let format = StickyFileFormat(stickies: stickies)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(format) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func loadFromDisk() -> [StickyNote] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let format = try? decoder.decode(StickyFileFormat.self, from: data) else { return [] }
        return format.stickies
    }
}
