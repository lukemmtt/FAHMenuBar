import Foundation

@MainActor
public protocol FAHClientProtocol: ObservableObject {
    var isConnected: Bool { get }
    var showConnectionStatus: Bool { get }
    var connectionStatus: String { get }
    var clientState: ClientState? { get }
    var lastError: String? { get }
    
    func connect()
    func disconnect()
    func refreshData()
    
    func pause(groupName: String?)
    func fold(groupName: String?)
    func finish(groupName: String?)
}