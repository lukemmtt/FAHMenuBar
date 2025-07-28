import Foundation

@MainActor
public protocol LoggingServiceProtocol {
    func log(_ message: String, level: LogLevel)
}

public enum LogLevel: String {
    case debug = "debug"
    case info = "info"
    case error = "error"
}