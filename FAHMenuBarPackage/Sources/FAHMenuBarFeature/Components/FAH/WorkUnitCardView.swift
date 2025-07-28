import SwiftUI

struct WorkUnitCardView: View {
    let activeUnit: FAHWorkUnit
    let clientState: ClientState
    let rotationAngle: Double
    let client: FAHClient
    
    var body: some View {
        let unitGroup = clientState.groups.first { $0.name == activeUnit.group }
        let unitState = activeUnit.state.uppercased()
        let isRunning = unitState == "RUN" && !(unitGroup?.paused ?? false)
        let isPaused = (unitGroup?.paused ?? false) || ["PAUSE", "PAUSED", "STOP", "STOPPED"].contains(unitState)
        let isFinishing = unitGroup?.finish ?? false
        
        let (icon, color): (String, Color) = {
            if isPaused {
                return ("hourglass", FAHColors.paused)
            } else if isFinishing {
                return ("arrow.2.circlepath", FAHColors.finishing)
            } else {
                return ("arrow.2.circlepath", FAHColors.running)
            }
        }()
        
        return VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .rotationEffect(.degrees(isRunning ? rotationAngle : 0))
                    .animation(.linear(duration: 1.0), value: rotationAngle)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let unitGroup = clientState.groups.first(where: { $0.name == activeUnit.group }) {
                        HStack {
                            Text(unitGroup.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if unitGroup.cpus > 0 || unitGroup.gpus > 0 {
                                Text("(\(unitGroup.cpus) CPUs" + (unitGroup.gpus > 0 ? ", \(unitGroup.gpus) GPUs)" : ")"))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    HStack {
                        Text("Project \(activeUnit.project)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if activeUnit.ppd > 0 {
                            Text("\(activeUnit.ppd) PPD")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
            }
            
            if activeUnit.progress > 0 {
                VStack(spacing: 4) {
                    ColoredProgressView(value: activeUnit.progress, total: 100, tintColor: color)
                    
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
            
            HStack(spacing: 6) {
                if isPaused {
                    Button(action: { client.fold(groupName: activeUnit.group) }) {
                        Text("Resume")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.small)
                } else {
                    Button(action: { client.pause(groupName: activeUnit.group) }) {
                        Text("Pause")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .controlSize(.small)
                }
                
                if isFinishing {
                    Button(action: { client.fold(groupName: activeUnit.group) }) {
                        Text("Continue")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .controlSize(.small)
                } else {
                    Button(action: { client.finish(groupName: activeUnit.group) }) {
                        Text("Finish")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .controlSize(.small)
                }
            }
            .padding(.top, 4)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.leading)
    }
}
