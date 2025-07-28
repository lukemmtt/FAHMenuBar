import Foundation

//
// FAHClient.swift
// FAHMenuBar
//
// Main coordinator/facade for Folding@home client functionality.
// Acts as a lightweight orchestrator of specialized services while maintaining
// the same public API for existing UI components.
//

@MainActor
public class FAHClient: ObservableObject, FAHClientProtocol {
    public static let shared = FAHClient()
    
    // Published properties that views observe
    @Published public var isConnected = false
    @Published public var showConnectionStatus = false
    @Published public var connectionStatus = "Disconnected"
    @Published public var clientState: ClientState?
    @Published public var lastError: String?
    
    // Service dependencies
    private let webSocketService: FAHWebSocketService
    private let dataParser: FAHDataParser
    private let commandService: FAHCommandService
    private let stateManager: FAHStateManager
    
    private init() {
        self.webSocketService = FAHWebSocketService()
        self.dataParser = FAHDataParser.shared
        self.commandService = FAHCommandService.shared
        self.stateManager = FAHStateManager.shared
        
        // Set up service connections
        webSocketService.delegate = self
        commandService.setWebSocketService(webSocketService)
        
        // Mirror service state to published properties
        setupStateBinding()
    }
    
    private func setupStateBinding() {
        // Bind WebSocket service state to published properties
        webSocketService.$isConnected
            .assign(to: &$isConnected)
        
        webSocketService.$connectionStatus
            .assign(to: &$connectionStatus)
            
        webSocketService.$lastError
            .assign(to: &$lastError)
        
        // Bind state manager state to published properties
        stateManager.$clientState
            .assign(to: &$clientState)
            
        stateManager.$showConnectionStatus
            .assign(to: &$showConnectionStatus)
    }
    
    // MARK: - Public API (maintains existing interface)
    
    public func connect() {
        webSocketService.connect()
    }
    
    public func disconnect() {
        webSocketService.disconnect()
        stateManager.clearState()
    }
    
    public func refreshData() {
        webSocketService.refreshConnection()
    }
    
    // MARK: - Control Commands
    
    public func pause(groupName: String? = nil) {
        commandService.pause(groupName: groupName)
    }
    
    public func fold(groupName: String? = nil) {
        commandService.fold(groupName: groupName)
    }
    
    public func finish(groupName: String? = nil) {
        commandService.finish(groupName: groupName)
    }
}

// MARK: - FAHWebSocketServiceDelegate

extension FAHClient: FAHWebSocketServiceDelegate {
    public func webSocketService(_ service: FAHWebSocketService, didReceiveMessage message: String, wasInitialConnection: Bool) {
        if let newState = dataParser.parseMessage(message) {
            stateManager.updateState(newState)
        }
        
        // Enable updates after initial connection (if needed)
        if wasInitialConnection {
            // The v8 API should send automatic updates after connection
        }
    }
}