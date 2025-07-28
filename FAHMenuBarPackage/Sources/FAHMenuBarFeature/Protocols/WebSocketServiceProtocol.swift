import Foundation

@MainActor
public protocol WebSocketServiceProtocol: ObservableObject {
    var isConnected: Bool { get }
    var connectionStatus: String { get }
    var lastError: String? { get }
    var delegate: FAHWebSocketServiceDelegate? { get set }
    
    func connect()
    func disconnect()
    func refreshConnection()
    func sendCommand(_ command: [String: Any])
}