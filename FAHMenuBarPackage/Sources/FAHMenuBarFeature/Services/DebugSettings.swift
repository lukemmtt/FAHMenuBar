import Foundation

@MainActor
class DebugSettings: ObservableObject {
    static let shared = DebugSettings()
    
    @Published var isDebugModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDebugModeEnabled, forKey: "FAHMenuBar_DebugMode")
        }
    }
    
    private init() {
        self.isDebugModeEnabled = UserDefaults.standard.bool(forKey: "FAHMenuBar_DebugMode")
    }
}