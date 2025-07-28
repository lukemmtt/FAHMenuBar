import Foundation

public struct FAHWorkUnit: Identifiable {
    public let id: String
    public let state: String
    public let project: Int
    public let run: Int
    public let clone: Int
    public let gen: Int
    public let core: String
    public let progress: Double
    public let eta: String
    public let ppd: Int
    public let creditestimate: Int
    public let waitingon: String
    public let group: String  // Track which group this unit belongs to
    
    public var statusColor: String {
        switch state.lowercased() {
        case "run", "running": return "green"
        case "download", "downloading": return "blue"
        case "upload", "uploading": return "blue"
        case "ready": return "orange"
        case "pause", "paused": return "orange"
        case "error", "failed": return "red"
        default: return "gray"
        }
    }
}