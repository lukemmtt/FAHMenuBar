import Foundation

struct MockData {
    private static func createMockGroupsData() -> [(name: String, description: String, idle: Bool, paused: Bool, finish: Bool, cpus: Int, gpus: Int)] {
        return [
            // Mock GPU group (paused) - use unique name to avoid conflicts with real API
            (name: "mock-gpu", description: "Mock GPU Group", idle: false, paused: true, finish: false, cpus: 0, gpus: 1),
            
            // Mock secondary CPU group (running)
            (name: "mock-secondary", description: "Mock Secondary CPU Group", idle: false, paused: false, finish: false, cpus: 4, gpus: 0),
            
            // Mock high-performance group (finishing)
            (name: "mock-high-perf", description: "Mock High Performance Group", idle: false, paused: false, finish: true, cpus: 8, gpus: 2),
            
            // Mock backup group (paused)
            (name: "mock-backup", description: "Mock Backup Group", idle: false, paused: true, finish: false, cpus: 2, gpus: 0),
            
            // Mock mixed group (running)
            (name: "mock-mixed", description: "Mock Mixed CPU+GPU Group", idle: false, paused: false, finish: false, cpus: 6, gpus: 3),
            
            // Mock power-saver group (finishing)
            (name: "mock-power-saver", description: "Mock Power Saver Group", idle: false, paused: false, finish: true, cpus: 1, gpus: 0)
        ]
    }
    
    static func createMockGroups() -> [ComputeGroup] {
        return createMockGroupsData().enumerated().map { (index, data) in
            ComputeGroup(
                index: index,
                name: data.name,
                description: data.description,
                idle: data.idle,
                paused: data.paused,
                finish: data.finish,
                cpus: data.cpus,
                gpus: data.gpus
            )
        }
    }
    
    static func createMockUnits() -> [FAHWorkUnit] {
        return [
            // Mock GPU unit (paused group = paused unit)
            FAHWorkUnit(
                id: "mock-gpu-unit",
                state: "paused", // Use lowercase to match real API
                project: 18764,
                run: 234,
                clone: 89,
                gen: 12,
                core: "0x23",
                progress: 67.5,
                eta: "Paused",
                ppd: 0, // Paused units have 0 PPD
                creditestimate: 125000,
                waitingon: "",
                group: "mock-gpu"
            ),
            
            // Mock secondary CPU unit (running group = running unit)
            FAHWorkUnit(
                id: "mock-secondary-unit",
                state: "running", // Use lowercase to match real API
                project: 16927,
                run: 45,
                clone: 123,
                gen: 8,
                core: "0xa8",
                progress: 23.7,
                eta: "3:45:00",
                ppd: 4500,
                creditestimate: 3200,
                waitingon: "",
                group: "mock-secondary"
            ),
            
            // Mock high-performance unit (finishing group = running unit with high progress)
            FAHWorkUnit(
                id: "mock-highperf-unit",
                state: "running", // Still running, but group is set to finish
                project: 19856,
                run: 78,
                clone: 45,
                gen: 23,
                core: "0x26",
                progress: 89.2,
                eta: "15:30",
                ppd: 12500,
                creditestimate: 8750,
                waitingon: "",
                group: "mock-high-perf"
            ),
            
            // Mock backup unit (paused group = paused unit)
            FAHWorkUnit(
                id: "mock-backup-unit",
                state: "paused", // Use lowercase to match real API
                project: 14892,
                run: 156,
                clone: 87,
                gen: 5,
                core: "0xa7",
                progress: 45.8,
                eta: "Paused",
                ppd: 0, // Paused units have 0 PPD
                creditestimate: 2100,
                waitingon: "",
                group: "mock-backup"
            ),
            
            // Mock mixed CPU+GPU unit (running group = running unit)
            FAHWorkUnit(
                id: "mock-mixed-unit",
                state: "running", // Use lowercase to match real API
                project: 17492,
                run: 234,
                clone: 167,
                gen: 15,
                core: "0x23",
                progress: 67.3,
                eta: "2:15:45",
                ppd: 18750,
                creditestimate: 15200,
                waitingon: "",
                group: "mock-mixed"
            ),
            
            // Mock power-saver unit (finishing group = running unit with high progress)
            FAHWorkUnit(
                id: "mock-powersaver-unit",
                state: "running", // Still running, but group is set to finish
                project: 13894,
                run: 89,
                clone: 234,
                gen: 7,
                core: "0xa4",
                progress: 95.1,
                eta: "8:30",
                ppd: 850,
                creditestimate: 750,
                waitingon: "",
                group: "mock-power-saver"
            )
        ]
    }
}