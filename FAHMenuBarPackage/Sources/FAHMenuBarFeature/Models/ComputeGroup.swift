import Foundation

public struct ComputeGroup: Identifiable {
    public let id = UUID()
    public let index: Int
    public let name: String
    public let description: String
    public let idle: Bool
    public let paused: Bool
    public let finish: Bool
    public let cpus: Int
    public let gpus: Int
    
    public var displayName: String {
        name.isEmpty ? "Default" : name
    }
}