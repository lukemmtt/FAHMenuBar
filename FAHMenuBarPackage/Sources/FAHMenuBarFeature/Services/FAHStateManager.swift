import Foundation

//
// FAHStateManager.swift
// FAHMenuBar
//
// Manages observable application state including client state and
// connection status. Provides a central place for UI components
// to observe and react to state changes.
//

@MainActor
public class FAHStateManager: ObservableObject, StateManagerProtocol {
    @Published public var clientState: ClientState?
    @Published public var showConnectionStatus = false
    
    public static let shared = FAHStateManager()
    
    private init() {}
    
    public func updateState(_ newState: ClientState) {
        self.clientState = newState
    }
    
    public func clearState() {
        self.clientState = nil
    }
    
    public func setShowConnectionStatus(_ show: Bool) {
        self.showConnectionStatus = show
    }
}