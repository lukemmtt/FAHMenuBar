import Foundation

//
// LoggingService.swift
// FAHMenuBar
//
// Centralized logging service that writes debug information to a file.
// Eliminates duplicate logging code and provides consistent log formatting
// across all services.
//

@MainActor
public class LoggingService: LoggingServiceProtocol {
    public static let shared = LoggingService()
    
    private let logFile: URL
    
    private init() {
        let logDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.logFile = logDir.appendingPathComponent("FAHMenuBar_debug.log")
    }
    
    public func log(_ message: String, level: LogLevel = .info) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] [\(level.rawValue.uppercased())] \(message)\n"
        
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }
    }
}

