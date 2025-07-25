import SwiftUI
import FAHMenuBarFeature
import Sparkle
import ServiceManagement

extension Notification.Name {
    static let popoverDidShow = Notification.Name("FAHMenuBarPopoverDidShow")
    static let popoverDidHide = Notification.Name("FAHMenuBarPopoverDidHide")
}

@main
struct FAHMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    private var updaterController: SPUStandardUpdaterController!
    private var eventMonitor: Any?
    private var isPopoverVisible = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        setupMenuBar()
        checkFirstLaunch()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "cube.fill", accessibilityDescription: "Folding@home")
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Use the official FAH v8 API client
        popover.contentViewController = NSHostingController(rootView: FAHMenuView())
        popover.behavior = .transient
        popover.delegate = self
    }
    
    // MARK: - NSPopoverDelegate
    
    func popoverDidClose(_ notification: Notification) {
        closePopover()
    }
    
    @objc func togglePopover() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right-click shows quit menu
            showRightClickMenu()
        } else {
            // Left-click toggles popover
            if let button = statusItem?.button {
                if isPopoverVisible {
                    closePopover()
                } else {
                    showPopover(button: button)
                }
            }
        }
    }
    
    func showRightClickMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit FAHMenuBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    func showPopover(button: NSStatusBarButton) {
        // Don't show if already visible
        guard !isPopoverVisible else { return }
        
        isPopoverVisible = true
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        startEventMonitor()
        
        // Notify that popover is shown
        NotificationCenter.default.post(name: .popoverDidShow, object: nil)
    }
    
    func closePopover() {
        // Don't close if already hidden
        guard isPopoverVisible else { return }
        
        isPopoverVisible = false
        popover.performClose(nil)
        stopEventMonitor()
        
        // Notify that popover is hidden
        NotificationCenter.default.post(name: .popoverDidHide, object: nil)
    }
    
    func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }
    
    func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    // MARK: - Auto-Launch Functions
    
    private func checkFirstLaunch() {
        // Check if this is the first launch
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            
            // Delay the prompt slightly so the menubar appears first
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showAutoLaunchPrompt()
            }
        }
    }
    
    private func showAutoLaunchPrompt() {
        let alert = NSAlert()
        alert.messageText = "Launch FAH MenuBar at Login?"
        alert.informativeText = "Would you like FAH MenuBar to start automatically when you log in? You can change this later in the menu."
        alert.addButton(withTitle: "Yes, Start at Login")
        alert.addButton(withTitle: "Not Now")
        alert.alertStyle = .informational
        
        if alert.runModal() == .alertFirstButtonReturn {
            enableAutoLaunch()
        }
    }
    
    func enableAutoLaunch() {
        do {
            try SMAppService.mainApp.register()
            UserDefaults.standard.set(true, forKey: "autoLaunchEnabled")
        } catch {
            // Silently fail
        }
    }
    
    func disableAutoLaunch() {
        do {
            try SMAppService.mainApp.unregister()
            UserDefaults.standard.set(false, forKey: "autoLaunchEnabled")
        } catch {
            // Silently fail
        }
    }
    
    @objc func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}