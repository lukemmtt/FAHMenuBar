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
        VStack(spacing: 8) {
            // Fixed Header - more compact
            HeaderView(clientState: client.clientState, rotationAngle: rotationAngle)
            
            // Fixed Status Info
            if let state = client.clientState {
                StatusInfoView(
                    clientState: state,
                    lastError: client.lastError,
                    rotationAngle: rotationAngle
                )
                
                Divider()
                
                // Work Units Section - scrollable only when needed
                let maxHeight = min(CGFloat(state.units.count * 120), 300)
                let needsScrolling = CGFloat(state.units.count * 120) > 300
                
                if needsScrolling {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(state.units) { activeUnit in
                                WorkUnitCardView(
                                    activeUnit: activeUnit,
                                    clientState: state,
                                    rotationAngle: rotationAngle,
                                    client: client
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: maxHeight)
                } else {
                    VStack(spacing: 8) {
                        ForEach(state.units) { activeUnit in
                            WorkUnitCardView(
                                activeUnit: activeUnit,
                                clientState: state,
                                rotationAngle: rotationAngle,
                                client: client
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Only show global controls when there are multiple active groups
                if state.activeGroupCount > 1 {
                    Divider()
                    
                    // Fixed Global Controls - more compact
                    GlobalControlsView(clientState: state, client: client)
                    
                    Divider()
                }
            }
            
            // Fixed Footer - more compact
            FooterActionsView(
                autoLaunchEnabled: $autoLaunchEnabled,
                showingAbout: $showingAbout,
                toggleAutoLaunch: toggleAutoLaunch
            )
        }
        .frame(width: 320)
        .frame(maxHeight: 600)
        .fixedSize(horizontal: false, vertical: true)
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
