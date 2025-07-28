import Foundation

//
// FAHDataParser.swift
// FAHMenuBar
//
// Parses JSON messages from the Folding@home v8 WebSocket API and
// constructs ClientState objects. Handles the complex nested JSON
// structure and data transformation logic.
//

@MainActor
public class FAHDataParser {
    public static let shared = FAHDataParser()
    
    private init() {}
    
    public func parseMessage(_ text: String) -> ClientState? {
        guard let data = text.data(using: .utf8) else { return nil }
        
        do {
            // Try to parse as JSON object first (initial state)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return parseClientState(json)
            } else if let _ = try JSONSerialization.jsonObject(with: data) as? [Any] {
                // Handle update arrays (subsequent updates from v8 API)
                // For now, ignore these and rely on the initial state
                return nil
            }
        } catch {
            // Ignore ping messages and parse errors
        }
        
        return nil
    }
    
    private func parseClientState(_ json: [String: Any]) -> ClientState {
        if DebugSettings.shared.isDebugModeEnabled {
            LoggingService.shared.log("Debug mode enabled - returning pure mock data", level: .debug)
            return createMockClientState()
        }
        
        // Real data parsing - minimal logging in production
        
        // Create client state from the JSON
        var state = ClientState()
        
        // Parse basic info from nested structures
        if let info = json["info"] as? [String: Any] {
            state.version = info["version"] as? String ?? "Unknown"
        }
        
        if let config = json["config"] as? [String: Any] {
            state.user = config["user"] as? String ?? ""
            state.team = config["team"] as? Int ?? 0
        }
        
        // Parse machine info
        if let info = json["info"] as? [String: Any] {
            state.hostname = info["hostname"] as? String ?? "Unknown"
            state.cpus = info["cpus"] as? Int ?? 0
            state.gpus = info["gpus"] as? Int ?? 0
        }
        
        // Parse current state (paused, running, etc.) from groups config
        if let groups = json["groups"] as? [String: [String: Any]] {
            if DebugSettings.shared.isDebugModeEnabled {
                LoggingService.shared.log("Found \(groups.count) groups", level: .debug)
                for (groupKey, groupData) in groups {
                    LoggingService.shared.log("Group '\(groupKey)': \(groupData)", level: .debug)
                    if let config = groupData["config"] as? [String: Any] {
                        let paused = config["paused"] as? Bool ?? false
                        let finish = config["finish"] as? Bool ?? false
                        LoggingService.shared.log("  - paused: \(paused), finish: \(finish)", level: .debug)
                    }
                }
            }
            
            if let defaultGroup = groups[""],
               let config = defaultGroup["config"] as? [String: Any] {
                state.paused = config["paused"] as? Bool ?? false
                state.finish = config["finish"] as? Bool ?? false
            }
        }
        
        // Parse units (work units)
        if let units = json["units"] as? [[String: Any]] {
            state.units = units.compactMap { unitData in
                
                // Get project from assignment
                let project = (unitData["assignment"] as? [String: Any])?["project"] as? Int ?? 0
                
                // Get run/clone/gen from wu
                let wu = unitData["wu"] as? [String: Any]
                let run = wu?["run"] as? Int ?? 0
                let clone = wu?["clone"] as? Int ?? 0  
                let gen = wu?["gen"] as? Int ?? 0
                
                // Get progress (0.0-1.0 range, convert to percentage)
                let progressDecimal = unitData["wu_progress"] as? Double ?? unitData["progress"] as? Double ?? 0.0
                let progressPercent = progressDecimal * 100.0
                
                // Get credit estimate from assignment
                let creditestimate = (unitData["assignment"] as? [String: Any])?["credit"] as? Int ?? 0
                
                let workUnit = FAHWorkUnit(
                    id: unitData["id"] as? String ?? "",
                    state: unitData["state"] as? String ?? "unknown",
                    project: project,
                    run: run,
                    clone: clone,
                    gen: gen,
                    core: ((unitData["assignment"] as? [String: Any])?["core"] as? [String: Any])?["type"] as? String ?? "",
                    progress: progressPercent,
                    eta: unitData["eta"] as? String ?? "",
                    ppd: unitData["ppd"] as? Int ?? 0,
                    creditestimate: creditestimate,
                    waitingon: unitData["waitingon"] as? String ?? "",
                    group: unitData["group"] as? String ?? ""
                )
                
                return workUnit
            }
        }
        
        // Parse groups (compute resources) - groups is a dictionary in v8
        if let groups = json["groups"] as? [String: [String: Any]] {
            state.groups = groups.enumerated().compactMap { (index, keyValue) in
                let (groupKey, groupData) = keyValue
                
                // Extract group-specific state
                let config = groupData["config"] as? [String: Any]
                let paused = config?["paused"] as? Bool ?? false
                let finish = config?["finish"] as? Bool ?? false
                let cpus = config?["cpus"] as? Int ?? 0
                let gpus = config?["gpus"] as? [Int] ?? []
                
                if DebugSettings.shared.isDebugModeEnabled {
                    LoggingService.shared.log("Creating ComputeGroup for '\(groupKey)': cpus=\(cpus), gpus=\(gpus.count), paused=\(paused), finish=\(finish)", level: .debug)
                    LoggingService.shared.log("GROUP STATE: '\(groupKey)' -> paused=\(paused), finish=\(finish) at \(Date())", level: .debug)
                }
                
                return ComputeGroup(
                    index: index,
                    name: groupKey, // Keep original group name, don't rename empty string
                    description: groupKey.isEmpty ? "Default Group" : "Group \(groupKey)",
                    idle: !(groupData["wait"] == nil),
                    paused: paused,
                    finish: finish,
                    cpus: cpus,
                    gpus: gpus.count
                )
            }
        }
        
        return state
    }
    
    private func createMockClientState() -> ClientState {
        var state = ClientState()
        
        // Mock basic info
        state.version = "8.4.9 (Mock)"
        state.user = "MockUser123"
        state.team = 234567
        state.hostname = "MockMachine"
        state.cpus = 16
        state.gpus = 2
        
        // Use pure mock data
        state.groups = MockData.createMockGroups()
        state.units = MockData.createMockUnits()
        
        LoggingService.shared.log("Mock data statusText: '\(state.statusText)'", level: .debug)
        LoggingService.shared.log("Mock data groups: \(state.groups.map { "\($0.name): paused=\($0.paused), finish=\($0.finish)" })", level: .debug)
        LoggingService.shared.log("Mock data activeGroupCount: \(state.activeGroupCount)", level: .debug)
        
        return state
    }
}