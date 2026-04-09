import Foundation
import SwiftUI

@MainActor
class StickyStore: ObservableObject {
    @Published var stickies: [StickyNote] = []

    private let fileURL: URL
    private var saveTask: Task<Void, Never>?

    static let shared = StickyStore()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("StickyTodos", isDirectory: true)

        if !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        }

        self.fileURL = appDir.appendingPathComponent("stickies.json")
        self.stickies = loadFromDisk()

        if stickies.isEmpty {
            var note = StickyNote()
            note.addTask(title: "Welcome to StickyTodos!")
            note.addTask(title: "Check me off for confetti 🎉")
            stickies.append(note)
            saveToDisk()
        }
    }

    // MARK: - CRUD Operations

    @discardableResult
    func createSticky() -> StickyNote {
        let note = StickyNote()
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
