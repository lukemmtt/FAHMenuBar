import SwiftUI
import AppKit

struct FooterActionsView: View {
    @Binding var autoLaunchEnabled: Bool
    @Binding var showingAbout: Bool
    let toggleAutoLaunch: () -> Void
    
    var body: some View {
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
        .padding(.bottom, 8)
    }
}