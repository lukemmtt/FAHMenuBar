import Foundation

//
// FAHCommandService.swift
// FAHMenuBar
//
// Handles sending control commands (pause, fold, finish) to the
// Folding@home client via WebSocket. Provides a clean interface
// for UI components to control folding operations.
//

@MainActor
public class FAHCommandService {
    public static let shared = FAHCommandService()
    
    private weak var webSocketService: FAHWebSocketService?
    
    private init() {}
    
    public func setWebSocketService(_ service: FAHWebSocketService) {
        self.webSocketService = service
    }
    
    public func pause(groupName: String? = nil) {
        LoggingService.shared.log("Sending pause command for group: \(groupName ?? "all")")
        if let group = groupName {
            sendCommand(["cmd": "state", "state": "pause", "group": group])
        } else {
            sendCommand(["cmd": "state", "state": "pause"])
        }
    }
    
    public func fold(groupName: String? = nil) {
        LoggingService.shared.log("COMMAND: Sending fold command for group: '\(groupName ?? "all")'")
        if let group = groupName {
            sendCommand(["cmd": "state", "state": "fold", "group": group])
        } else {
            sendCommand(["cmd": "state", "state": "fold"])
        }
    }
    
    public func finish(groupName: String? = nil) {
        LoggingService.shared.log("Sending finish command for group: \(groupName ?? "all")")
        if let group = groupName {
            sendCommand(["cmd": "state", "state": "finish", "group": group])
        } else {
            sendCommand(["cmd": "state", "state": "finish"])
        }
    }
    
    private func sendCommand(_ command: [String: Any]) {
        webSocketService?.sendCommand(command)
    }
}