import SwiftUI
import AppKit
import ServiceManagement

public struct FAHMenuView: View {
    @StateObject private var client = FAHClient.shared
    @State private var autoLaunchEnabled = false
    @State private var updateTimer: Timer?
    @State private var rotationAngle: Double = 0
    @State private var isViewActive = false
    @State private var isProcessingNotification = false
    @State private var showingAbout = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            
            // Header
            HStack {
                Image(systemName: "cube.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Folding@home")
                    .font(.headline)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
            
            // Status and Info
            VStack(alignment: .leading, spacing: 8) {
                if let error = client.lastError {
                    Text("Error: \(error)")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
                
                // Client Info
                if let state = client.clientState {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(state.statusText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(statusColor(for: state.statusText))
                            Spacer()
                            if state.totalPPD > 0 {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(state.totalPPD) PPD")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("\(Int(state.estimatedCreditsPerHour)) credits/hr")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if state.team > 0 {
                            Text("Team: \(state.team)")
                                .font(.caption2)
                        }
                        
                        if state.cpus > 0 || state.gpus > 0 {
                            Text("Resources: \(state.cpus) CPUs, \(state.gpus) GPUs")
                                .font(.caption2)
                        }
                    }
                    .padding(.leading)
                    
                    // Primary Work Unit Progress
                    if let activeUnit = state.runningUnits.first ?? state.units.first {
                        VStack(spacing: 6) {
                            HStack {
                                // Use FAH web client style icons based on work unit state or global state
                                let unitState = activeUnit.state.uppercased()
                                let isRunning = unitState == "RUN" && !state.paused
                                let isPaused = state.paused || ["PAUSE", "PAUSED", "STOP", "STOPPED"].contains(unitState)
                                
                                Image(systemName: isRunning ? "arrow.2.circlepath" : isPaused ? "hourglass" : "cube.fill")
                                    .foregroundColor(isRunning ? .green : isPaused ? .orange : .secondary)
                                    .font(.title3)
                                    .rotationEffect(.degrees(isRunning ? rotationAngle : 0))
                                    .animation(.linear(duration: 1.0), value: rotationAngle)
                                
                                Text("Project \(activeUnit.project)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            if activeUnit.progress > 0 {
                                VStack(spacing: 4) {
                                    // FAH web client style progress bar - check both unit state and global state
                                    let unitState = activeUnit.state.uppercased()
                                    let isRunning = unitState == "RUN" && !state.paused
                                    let isPaused = state.paused || ["PAUSE", "PAUSED", "STOP", "STOPPED"].contains(unitState)
                                    let progressColor = isRunning ? Color.green : isPaused ? Color.orange : Color.blue
                                    
                                    ColoredProgressView(value: activeUnit.progress, total: 100, tintColor: progressColor)
                                    
                                    HStack {
                                        Text("\(String(format: "%.1f", activeUnit.progress))%")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Spacer()
                                        if !activeUnit.eta.isEmpty {
                                            Text("ETA: \(activeUnit.eta)")
                                                .font(.caption)
                                        }
                                    }
                                    .foregroundColor(.secondary)
                                }
                            }
                            
                            if activeUnit.creditestimate > 0 {
                                Text("Estimated Credits: \(activeUnit.creditestimate)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.leading)
                        
                        // Additional Work Units (if any)
                        if state.units.count > 1 {
                            Text("\(state.units.count - 1) more work unit\(state.units.count == 2 ? "" : "s")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.leading)
                                .padding(.top, 2)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Control Buttons
            if let state = client.clientState {
                let isPausedOrStopped = state.paused || state.units.allSatisfy { unit in
                    let unitState = unit.state.uppercased()
                    return unitState == "PAUSE" || unitState == "PAUSED" || unitState == "STOP" || unitState == "STOPPED"
                }
                
                HStack(spacing: 8) {
                    if isPausedOrStopped {
                        Button(action: { client.fold() }) {
                            Label("Resume", systemImage: "arrow.2.circlepath")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    } else {
                        Button(action: { client.pause() }) {
                            Label("Pause", systemImage: "pause.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                    
                    Button(action: { client.finish() }) {
                        Label("Finish", systemImage: "stop.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // Footer Actions
            VStack(spacing: 8) {
                // First row
                HStack {
                    Button("Open Web Client") {
                        NSWorkspace.shared.open(URL(string: "https://v8-4.foldingathome.org/")!)
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    
                    Spacer()
                    
                    Menu {
                        Button("Start at Login: \(autoLaunchEnabled ? "On" : "Off")") {
                            toggleAutoLaunch()
                        }
                        
                        Button("Check for Updates") {
                            // Access updater through app delegate using NSApplication
                            if let appDelegate = NSApplication.shared.delegate as? NSObject {
                                let selector = NSSelectorFromString("checkForUpdates")
                                if appDelegate.responds(to: selector) {
                                    appDelegate.perform(selector)
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button("Official Folding@home Project") {
                            NSWorkspace.shared.open(URL(string: "https://foldingathome.org/")!)
                        }
                        
                        Button("About FAHMenuBar") {
                            showingAbout = true
                        }
                        
                        Divider()
                        
                        Button("Quit FAHMenuBar") {
                            NSApplication.shared.terminate(nil)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .frame(width: 40, height: 32)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            
        }
        .frame(width: 320)
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FAHMenuBarPopoverDidShow"))) { _ in
            // Prevent duplicate processing
            guard !isProcessingNotification else { return }
            isProcessingNotification = true
            defer { 
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isProcessingNotification = false
                }
            }
            
            // Invalidate any existing timer first
            if let existingTimer = updateTimer {
                existingTimer.invalidate()
                updateTimer = nil
            }
            
            isViewActive = true
            if !client.isConnected {
                client.connect()
            }
            checkAutoLaunchStatus()
            
            // Start timer to refresh FAH data
            updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                Task { @MainActor in
                    // Check both flags to ensure we should still be active
                    guard isViewActive && updateTimer != nil else {
                        return
                    }
                    
                    // Refresh data
                    client.refreshData()
                    // Rotate animation  
                    withAnimation(.linear(duration: 1.0)) {
                        rotationAngle += 180
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FAHMenuBarPopoverDidHide"))) { _ in
            isViewActive = false
            
            // Stop the timer
            if let timer = updateTimer {
                timer.invalidate()
                updateTimer = nil
            }
            
            // Disconnect client
            client.disconnect()
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "folding": return .green
        case "paused": return .orange
        case "finishing": return .blue
        case "idle": return .secondary
        default: return .secondary
        }
    }
    
    // MARK: - Auto-Launch Functions
    
    private func checkAutoLaunchStatus() {
        autoLaunchEnabled = SMAppService.mainApp.status == .enabled
    }
    
    private func toggleAutoLaunch() {
        do {
            if autoLaunchEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            autoLaunchEnabled.toggle()
        } catch {
            // Silently fail - the UI will reflect the current state on next check
        }
    }
}
