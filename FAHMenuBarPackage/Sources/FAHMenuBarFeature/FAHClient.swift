import Foundation

@MainActor
public class FAHClient: ObservableObject {
    public static let shared = FAHClient()
    
    @Published public var isConnected = false
    @Published public var showConnectionStatus = false
    @Published public var connectionStatus = "Disconnected"
    @Published public var clientState: ClientState?
    @Published public var lastError: String?
    private var errorTimer: Timer?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession? = URLSession(configuration: .default)
    
    // Official FAH v8 WebSocket API endpoint
    private let host = "localhost"
    private let port = 7396
    private let path = "/api/websocket"
    
    private init() {}
    
    public func connect() {
        guard let url = URL(string: "ws://\(host):\(port)\(path)") else {
            lastError = "Invalid WebSocket URL"
            return
        }
        
        connectionStatus = "Connecting..."
        // Don't show connection status for normal connections
        
        // Enable receiving messages
        shouldReceiveMessages = true
        
        // Create new session if needed (after disconnect)
        if session == nil {
            session = URLSession(configuration: .default)
        }
        
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessage()
        
        // The API sends full client state upon connection, so no need to request it
    }
    
    /// Enable automatic updates from the FAH v8 WebSocket API
    /// Based on FAH v8 web client implementation:
    /// https://github.com/FoldingAtHome/fah-web-client-bastet
    /// The API documentation discussion: https://github.com/FoldingAtHome/fah-client-bastet/discussions/215
    private func enableUpdates() {
        // The v8 API should send automatic updates after connection
    }
    
    public func disconnect() {
        // Stop receiving messages
        shouldReceiveMessages = false
        
        // Set disconnected state
        isConnected = false
        
        // Cancel any pending error timer
        errorTimer?.invalidate()
        errorTimer = nil
        
        // Cancel the websocket
        if let task = webSocketTask {
            task.cancel(with: .goingAway, reason: Data())
        }
        webSocketTask = nil
        
        // Clear all state
        connectionStatus = "Disconnected"
        clientState = nil
        lastError = nil
        
        // Invalidate URLSession
        session?.invalidateAndCancel()
        session = nil  // Will be recreated on next connect
    }
    
    /// Request an update from the existing connection
    public func refreshData() {
        // Only refresh if we should be receiving messages
        guard shouldReceiveMessages else { 
            return 
        }
        
        // Store the shouldReceiveMessages state
        let shouldContinue = shouldReceiveMessages
        
        // Quick reconnect to get fresh state
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        
        // Restore the flag and reconnect
        shouldReceiveMessages = shouldContinue
        if shouldContinue {
            connect()
        }
    }
    
    private var shouldReceiveMessages = true
    
    private func receiveMessage() {
        guard shouldReceiveMessages else { 
            return 
        }
        
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                Task { @MainActor in
                    // Check if we should still be receiving messages
                    guard self.shouldReceiveMessages && self.webSocketTask != nil else { 
                        return 
                    }
                    
                    switch message {
                    case .string(let text):
                        self.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                    
                    // Continue receiving messages only if still connected
                    if self.shouldReceiveMessages && self.webSocketTask != nil {
                        self.receiveMessage()
                    }
                }
                
            case .failure(let error):
                Task { @MainActor in
                    
                    // Delay showing connection errors to avoid blips during state transitions
                    self.errorTimer?.invalidate()
                    self.errorTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { _ in
                        Task { @MainActor in
                            self.isConnected = false
                            self.showConnectionStatus = true
                            self.connectionStatus = "Connection error"
                            self.lastError = error.localizedDescription
                        }
                    }
                }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            // Try to parse as JSON object first (initial state)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // First message should contain full client state
                let wasConnected = isConnected
                if !isConnected {
                    isConnected = true
                    connectionStatus = "Connected"
                    // Clear errors and cancel error timer when successfully connected
                    errorTimer?.invalidate()
                    lastError = nil
                }
                
                // Parse client state
                parseClientState(json)
                
                // Enable updates after initial connection
                if !wasConnected {
                    enableUpdates()
                }
            } else if let updateArray = try JSONSerialization.jsonObject(with: data) as? [Any] {
                // Handle update arrays (subsequent updates from v8 API)
                // For now, ignore these and rely on the initial state
                // The FAH client sends these periodically with incremental updates
            }
        } catch {
            // Ignore ping messages and parse errors
        }
    }
    
    private func parseClientState(_ json: [String: Any]) {
        // Create client state from the JSON
        var state = ClientState()
        
        // Parse basic info from nested structures
        if let info = json["info"] as? [String: Any] {
            state.version = info["version"] as? String ?? "Unknown"
        }
        
        if let config = json["config"] as? [String: Any] {
            state.user = config["user"] as? String ?? ""
            state.team = config["team"] as? Int ?? 0
        }
        
        // Parse machine info
        if let info = json["info"] as? [String: Any] {
            state.hostname = info["hostname"] as? String ?? "Unknown"
            state.cpus = info["cpus"] as? Int ?? 0
            state.gpus = info["gpus"] as? Int ?? 0
        }
        
        // Parse current state (paused, running, etc.) from groups config
        if let groups = json["groups"] as? [String: [String: Any]],
           let defaultGroup = groups[""],
           let config = defaultGroup["config"] as? [String: Any] {
            state.paused = config["paused"] as? Bool ?? false
            state.finish = config["finish"] as? Bool ?? false
        }
        
        // Parse units (work units)
        if let units = json["units"] as? [[String: Any]] {
            state.units = units.compactMap { unitData in
                
                // Get project from assignment
                let project = (unitData["assignment"] as? [String: Any])?["project"] as? Int ?? 0
                
                // Get run/clone/gen from wu
                let wu = unitData["wu"] as? [String: Any]
                let run = wu?["run"] as? Int ?? 0
                let clone = wu?["clone"] as? Int ?? 0  
                let gen = wu?["gen"] as? Int ?? 0
                
                // Get progress (0.0-1.0 range, convert to percentage)
                let progressDecimal = unitData["wu_progress"] as? Double ?? unitData["progress"] as? Double ?? 0.0
                let progressPercent = progressDecimal * 100.0
                
                // Get credit estimate from assignment
                let creditestimate = (unitData["assignment"] as? [String: Any])?["credit"] as? Int ?? 0
                
                let workUnit = FAHWorkUnit(
                    id: unitData["id"] as? String ?? "",
                    state: unitData["state"] as? String ?? "unknown",
                    project: project,
                    run: run,
                    clone: clone,
                    gen: gen,
                    core: ((unitData["assignment"] as? [String: Any])?["core"] as? [String: Any])?["type"] as? String ?? "",
                    progress: progressPercent,
                    eta: unitData["eta"] as? String ?? "",
                    ppd: unitData["ppd"] as? Int ?? 0,
                    creditestimate: creditestimate,
                    waitingon: unitData["waitingon"] as? String ?? ""
                )
                
                return workUnit
            }
        }
        
        // Parse groups (compute resources) - groups is a dictionary in v8
        if let groups = json["groups"] as? [String: [String: Any]] {
            state.groups = groups.enumerated().map { (index, keyValue) in
                let (groupKey, groupData) = keyValue
                
                return ComputeGroup(
                    index: index,
                    type: groupKey.isEmpty ? "default" : groupKey,
                    description: "Group \(groupKey.isEmpty ? "default" : groupKey)",
                    idle: !(groupData["wait"] == nil)
                )
            }
        }
        
        self.clientState = state
    }
    
    // MARK: - Control Commands
    
    public func pause() {
        sendCommand(["cmd": "state", "state": "pause"])
        // Request fresh state after command
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.requestStateUpdate()
        }
    }
    
    public func fold() {
        sendCommand(["cmd": "state", "state": "fold"])
        // Request fresh state after command
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.requestStateUpdate()
        }
    }
    
    public func finish() {
        sendCommand(["cmd": "state", "state": "finish"])
        // Request fresh state after command
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.requestStateUpdate()
        }
    }
    
    private func requestStateUpdate() {
        // FAH v8 sends full state on connection, so we reconnect to get fresh state
        let wasConnected = isConnected
        if wasConnected {
            // Brief disconnect and reconnect to trigger state update
            webSocketTask?.cancel(with: .normalClosure, reason: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.connect()
            }
        }
    }
    
    private func sendCommand(_ command: [String: Any]) {
        guard let webSocketTask = webSocketTask else {
            lastError = "Not connected"
            return
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: command)
            let text = String(data: data, encoding: .utf8) ?? "{}"
            
            webSocketTask.send(.string(text)) { error in
                if let error = error {
                    Task { @MainActor in
                        self.lastError = "Send failed: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            lastError = "Failed to send command"
        }
    }
}

// MARK: - Data Models

public struct ClientState {
    public var version: String = ""
    public var user: String = ""
    public var team: Int = 0
    public var hostname: String = ""
    public var cpus: Int = 0
    public var gpus: Int = 0
    public var paused: Bool = false
    public var finish: Bool = false
    public var units: [FAHWorkUnit] = []
    public var groups: [ComputeGroup] = []
    
    public var statusText: String {
        if finish {
            return "Finishing"
        } else if paused {
            return "Paused"
        } else if !units.isEmpty {
            return "Folding"
        } else {
            return "Idle"
        }
    }
    
    public var runningUnits: [FAHWorkUnit] {
        units.filter { $0.state.lowercased() == "run" || $0.state.lowercased() == "running" }
    }
    
    public var totalPPD: Int {
        units.reduce(0) { $0 + $1.ppd }
    }
}

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

public struct ComputeGroup {
    public let index: Int
    public let type: String
    public let description: String
    public let idle: Bool
}