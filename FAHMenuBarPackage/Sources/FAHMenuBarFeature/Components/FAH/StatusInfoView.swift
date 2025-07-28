import SwiftUI

struct StatusInfoView: View {
    let clientState: ClientState
    let lastError: String?
    let rotationAngle: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = lastError {
                Text("Error: \(error)")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .lineLimit(2)
            }
            
            // Client Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(clientState.statusText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor(for: clientState.statusText))
                    Spacer()
                    if clientState.totalPPD > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(clientState.totalPPD) PPD")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("\(Int(clientState.estimatedCreditsPerHour)) credits/hr")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if clientState.team > 0 {
                    Text("Team: \(clientState.team)")
                        .font(.caption2)
                }
            }
            .padding(.leading)
        }
        .padding(.horizontal)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "folding", "folding (partial)": return FAHColors.running
        case "paused": return FAHColors.paused
        case "finishing", "finishing (partial)": return FAHColors.finishing
        case "idle": return .secondary
        default: return .secondary
        }
    }
}