import Foundation

enum WebhookEventType: String, Codable {
    case taskCreated = "task.created"
    case taskCompleted = "task.completed"
    case taskUncompleted = "task.uncompleted"
    case taskDeleted = "task.deleted"
}

struct WebhookEvent: Codable {
    let eventType: String
    let timestamp: String
    let stickyId: String
    let stickyName: String
    let task: WebhookTaskPayload

    struct WebhookTaskPayload: Codable {
        let title: String
        let isCompleted: Bool
    }

    init(type: WebhookEventType, stickyID: UUID, stickyName: String, task: TodoItem) {
        self.eventType = type.rawValue
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.stickyId = stickyID.uuidString
        self.stickyName = stickyName
        self.task = WebhookTaskPayload(title: task.title, isCompleted: task.isCompleted)
    }

    var jsonData: Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(self)
    }
}
