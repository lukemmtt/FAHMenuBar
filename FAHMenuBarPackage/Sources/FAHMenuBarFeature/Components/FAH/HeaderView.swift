import SwiftUI

struct HeaderView: View {
    let clientState: ClientState?
    let rotationAngle: Double
    
    var body: some View {
        HStack {
            Text("Folding@home")
                .font(.headline)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var statusIcon: String {
        guard let state = clientState else { return "pause.circle.fill" }
        
        let status = state.statusText.lowercased()
        LoggingService.shared.log("HeaderView statusIcon - status: '\(status)'", level: .debug)
        
        switch status {
        case "folding", "folding (partial)": return "cube.fill"
        case "paused": return "pause.circle.fill"
        case "finishing", "finishing (partial)": return "stop.circle.fill"
        case "idle": return "pause.circle.fill"
        default: 
            LoggingService.shared.log("HeaderView statusIcon - no match for '\(status)', using pause.circle.fill", level: .debug)
            return "pause.circle.fill"
        }
    }
    
    private var statusColor: Color {
        guard let state = clientState else { return .secondary }
        
        switch state.statusText.lowercased() {
        case "folding", "folding (partial)": return .green
        case "paused": return .orange
        case "finishing", "finishing (partial)": return .blue
        case "idle": return .secondary
        default: return .secondary
        }
    }
    
    private var shouldRotate: Bool {
        guard let state = clientState else { return false }
        return state.statusText.lowercased().contains("folding")
    }
}