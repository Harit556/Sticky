import Foundation

class ZapierWebhookService {
    static let shared = ZapierWebhookService()

    private let session = URLSession.shared

    // UserDefaults keys
    private let enabledKey = "zapier_enabled"
    private let taskCompletedURLKey = "zapier_url_task_completed"
    private let taskCreatedURLKey = "zapier_url_task_created"
    private let taskDeletedURLKey = "zapier_url_task_deleted"

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    var taskCompletedURL: String {
        get { UserDefaults.standard.string(forKey: taskCompletedURLKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: taskCompletedURLKey) }
    }

    var taskCreatedURL: String {
        get { UserDefaults.standard.string(forKey: taskCreatedURLKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: taskCreatedURLKey) }
    }

    var taskDeletedURL: String {
        get { UserDefaults.standard.string(forKey: taskDeletedURLKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: taskDeletedURLKey) }
    }

    func fireEvent(type: WebhookEventType, stickyID: UUID, stickyName: String, task: TodoItem) {
        guard isEnabled else { return }

        let urlString: String
        switch type {
        case .taskCompleted, .taskUncompleted:
            urlString = taskCompletedURL
        case .taskCreated:
            urlString = taskCreatedURL
        case .taskDeleted:
            urlString = taskDeletedURL
        }

        guard !urlString.isEmpty, let url = URL(string: urlString) else { return }

        let event = WebhookEvent(type: type, stickyID: stickyID, stickyName: stickyName, task: task)
        guard let body = event.jsonData else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        // Fire and forget with one retry
        Task {
            do {
                let (_, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    // Retry once
                    _ = try? await session.data(for: request)
                }
            } catch {
                // Retry once on network error
                _ = try? await session.data(for: request)
            }
        }
    }

    func testWebhook(urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }

        let testEvent = WebhookEvent(
            type: .taskCompleted,
            stickyID: UUID(),
            stickyName: "Test Sticky",
            task: TodoItem(title: "Test task from StickyTodos", isCompleted: true)
        )

        guard let body = testEvent.jsonData else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            return false
        }
    }
}
