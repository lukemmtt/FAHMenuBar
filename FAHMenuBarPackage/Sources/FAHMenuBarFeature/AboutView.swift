import SwiftUI
import AppKit

public struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with app icon and title
            VStack(spacing: 16) {
                Image(systemName: "cube.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
                    .padding(.top, 8)
                
                VStack(spacing: 6) {
                    Text("FAHMenuBar")
                        .font(.title)
                        .fontWeight(.medium)
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 24)
            
            // Description
            Text("A modern menu bar app for monitoring and controlling your Folding@home client.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            
            // Links section
            HStack(spacing: 32) {
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://github.com/lukemmtt/FAHMenuBar")!)
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 18))
                            .foregroundColor(.accentColor)
                        Text("FAHMenuBar Project Home")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://foldingathome.org/")!)
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                            .foregroundColor(.accentColor)
                        Text("Official Folding@home Project")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 40)
            
            Spacer()
            
            // Disclaimer - subtle and at bottom
            VStack(spacing: 12) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 32)
                
                Text("FAHMenuBar is an independent project and is not officially affiliated with, endorsed by, or sponsored by the Folding@home project.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary.opacity(0.8))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                
                // Close button
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.top, 8)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(width: 420, height: 480)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    AboutView()
}