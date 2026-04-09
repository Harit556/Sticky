import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var showZapierSettings = false
}
