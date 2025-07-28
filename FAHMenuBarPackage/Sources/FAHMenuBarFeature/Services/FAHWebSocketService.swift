import Foundation

//
// FAHWebSocketService.swift
// FAHMenuBar
//
// Handles WebSocket connection management and message handling for
// the Folding@home v8 API. Manages connection lifecycle, error handling,
// and delegates message processing to other components.
//

@MainActor
public class FAHWebSocketService: ObservableObject, WebSocketServiceProtocol {
    @Published public var isConnected = false
    @Published public var connectionStatus = "Disconnected"
    @Published public var lastError: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var errorTimer: Timer?
    private var shouldReceiveMessages = true
    
    // Official FAH v8 WebSocket API endpoint
    private let host = "localhost"
    private let port = 7396
    private let path = "/api/websocket"
    
    public weak var delegate: FAHWebSocketServiceDelegate?
    
    public init() {
        self.session = URLSession(configuration: .default)
    }
    
    public func connect() {
        guard let url = URL(string: "ws://\(host):\(port)\(path)") else {
            lastError = "Invalid WebSocket URL"
            return
        }
        
        connectionStatus = "Connecting..."
        shouldReceiveMessages = true
        
        // Create new session if needed (after disconnect)
        if session == nil {
            session = URLSession(configuration: .default)
        }
        
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessage()
    }
    
    public func disconnect() {
        shouldReceiveMessages = false
        isConnected = false
        
        // Cancel any pending error timer
        errorTimer?.invalidate()
        errorTimer = nil
        
        // Cancel the websocket
        if let task = webSocketTask {
            task.cancel(with: .goingAway, reason: Data())
        }
        webSocketTask = nil
        
        // Clear state
        connectionStatus = "Disconnected"
        lastError = nil
        
        // Invalidate URLSession
        session?.invalidateAndCancel()
        session = nil
    }
    
    public func refreshConnection() {
        guard shouldReceiveMessages else { return }
        
        let shouldContinue = shouldReceiveMessages
        
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        
        shouldReceiveMessages = shouldContinue
        if shouldContinue {
            connect()
        }
    }
    
    public func sendCommand(_ command: [String: Any]) {
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
    
    private func receiveMessage() {
        guard shouldReceiveMessages else { return }
        
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                Task { @MainActor in
                    guard self.shouldReceiveMessages && self.webSocketTask != nil else { return }
                    
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
                            self.connectionStatus = "Connection error"
                            self.lastError = error.localizedDescription
                        }
                    }
                }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        LoggingService.shared.log("RAW MESSAGE: \(text)")
        
        let wasConnected = isConnected
        if !isConnected {
            isConnected = true
            connectionStatus = "Connected"
            // Clear errors and cancel error timer when successfully connected
            errorTimer?.invalidate()
            lastError = nil
        }
        
        // Notify delegate of new message
        delegate?.webSocketService(self, didReceiveMessage: text, wasInitialConnection: !wasConnected)
    }
}

@MainActor
public protocol FAHWebSocketServiceDelegate: AnyObject {
    func webSocketService(_ service: FAHWebSocketService, didReceiveMessage message: String, wasInitialConnection: Bool)
}