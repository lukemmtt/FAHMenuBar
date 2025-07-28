import Foundation

public struct ClientState {
    public var version: String = ""
    public var user: String = ""
    public var team: Int = 0
    public var hostname: String = ""
    public var cpus: Int = 0
    public var gpus: Int = 0
    public var paused: Bool = false  // Deprecated - use group states instead
    public var finish: Bool = false  // Deprecated - use group states instead
    public var units: [FAHWorkUnit] = []
    public var groups: [ComputeGroup] = []
    
    // Helper to get only active groups (groups with actual compute resources)
    // 
    // FAH v8 API Behavior Notes:
    // The FAH v8 client pre-creates multiple groups based on system configuration,
    // not just active folding work:
    // 
    // 1. "Default" group: Always created as fallback/template (usually 0 cpus, 0 gpus)
    // 2. "" (empty string): Often the actual active folding group 
    // 3. "gpu" group: Created if system has CUDA-capable GPUs, even if GPU folding
    //    is disabled or incompatible (shows 0 cpus, 0 gpus when inactive)
    // 
    // For UI purposes, we only consider groups with actual compute resources (cpus > 0 || gpus > 0)
    // as "active" to avoid showing "partial" states when only template groups exist.
    private var activeGroups: [ComputeGroup] {
        groups.filter { $0.cpus > 0 || $0.gpus > 0 }
    }
    
    // Public property for UI logic
    public var activeGroupCount: Int {
        activeGroups.count
    }
    
    // Computed properties for overall state
    public var isAnyGroupPaused: Bool {
        activeGroups.contains { $0.paused }
    }
    
    public var isAnyGroupFinishing: Bool {
        activeGroups.contains { $0.finish }
    }
    
    public var areAllGroupsPaused: Bool {
        !activeGroups.isEmpty && activeGroups.allSatisfy { $0.paused }
    }
    
    public var areAllGroupsFinishing: Bool {
        !activeGroups.isEmpty && activeGroups.allSatisfy { $0.finish }
    }
    
    public var statusText: String {
        // Check groups for state - prioritize running/folding over paused
        if areAllGroupsFinishing {
            return "Finishing"
        } else if isAnyGroupFinishing {
            return "Finishing (partial)"
        } else if !units.isEmpty && !areAllGroupsPaused {
            // If we have units and not all groups are paused, we're folding
            return isAnyGroupPaused ? "Folding (partial)" : "Folding"
        } else if areAllGroupsPaused {
            return "Paused"
        } else {
            return "Idle"
        }
    }
    
    public var runningUnits: [FAHWorkUnit] {
        units.filter { $0.state.lowercased() == "run" || $0.state.lowercased() == "running" }
    }
    
    public var totalPPD: Int {
        units.reduce(0) { $0 + $1.ppd }
    }
    
    public var estimatedCreditsPerHour: Double {
        // PPD = Points Per Day, so divide by 24 to get credits per hour
        return Double(totalPPD) / 24.0
    }
    
    // Get PPD for a specific group
    public func ppd(for groupName: String) -> Int {
        units.filter { $0.group == groupName }.reduce(0) { $0 + $1.ppd }
    }
    
    // Get units for a specific group
    public func units(for groupName: String) -> [FAHWorkUnit] {
        units.filter { $0.group == groupName }
    }
}