import Foundation

@MainActor
public protocol StateManagerProtocol: ObservableObject {
    var clientState: ClientState? { get }
    var showConnectionStatus: Bool { get }
    
    func updateState(_ newState: ClientState)
    func clearState()
    func setShowConnectionStatus(_ show: Bool)
}