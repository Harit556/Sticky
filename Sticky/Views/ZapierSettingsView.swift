import SwiftUI

struct ZapierSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State private var isEnabled: Bool
    @State private var taskCompletedURL: String
    @State private var taskCreatedURL: String
    @State private var taskDeletedURL: String

    @State private var testingURL: String?
    @State private var testResults: [String: Bool] = [:]

    private let service = ZapierWebhookService.shared

    init() {
        let svc = ZapierWebhookService.shared
        _isEnabled = State(initialValue: svc.isEnabled)
        _taskCompletedURL = State(initialValue: svc.taskCompletedURL)
        _taskCreatedURL = State(initialValue: svc.taskCreatedURL)
        _taskDeletedURL = State(initialValue: svc.taskDeletedURL)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Zapier Integration")
                .font(.title2.bold())

            Text("Connect Sticky to hundreds of apps via Zapier webhooks.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Enable Zapier Integration", isOn: $isEnabled)

            if isEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to set up:")
                        .font(.subheadline.bold())
                    Text("1. Create a Zap on zapier.com\n2. Choose \"Webhooks by Zapier\" → \"Catch Hook\" as trigger\n3. Copy the webhook URL and paste it below")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    webhookField(
                        label: "Task Completed",
                        url: $taskCompletedURL,
                        key: "completed"
                    )

                    webhookField(
                        label: "Task Created",
                        url: $taskCreatedURL,
                        key: "created"
                    )

                    webhookField(
                        label: "Task Deleted",
                        url: $taskDeletedURL,
                        key: "deleted"
                    )
                }
                .padding(.leading, 4)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    service.isEnabled = isEnabled
                    service.taskCompletedURL = taskCompletedURL
                    service.taskCreatedURL = taskCreatedURL
                    service.taskDeletedURL = taskDeletedURL
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 480, height: isEnabled ? 500 : 200)
    }

    @ViewBuilder
    private func webhookField(label: String, url: Binding<String>, key: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())

            HStack {
                TextField("https://hooks.zapier.com/hooks/catch/...", text: url)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))

                Button(action: {
                    testWebhook(urlString: url.wrappedValue, key: key)
                }) {
                    if testingURL == key {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 50)
                    } else if let result = testResults[key] {
                        HStack(spacing: 2) {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result ? .green : .red)
                            Text(result ? "OK" : "Fail")
                                .font(.caption)
                        }
                        .frame(width: 50)
                    } else {
                        Text("Test")
                            .frame(width: 50)
                    }
                }
                .disabled(url.wrappedValue.isEmpty || testingURL != nil)
            }
        }
    }

    private func testWebhook(urlString: String, key: String) {
        testingURL = key
        testResults.removeValue(forKey: key)

        Task {
            let result = await service.testWebhook(urlString: urlString)
            await MainActor.run {
                testResults[key] = result
                testingURL = nil
            }
        }
    }
}
