import Foundation

struct TodoItem: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var sortOrder: Int

    init(id: UUID = UUID(), title: String = "", isCompleted: Bool = false, sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
    }
}
