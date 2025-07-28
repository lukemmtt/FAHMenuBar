import SwiftUI

struct GlobalControlsView: View {
    let clientState: ClientState
    let client: FAHClient
    
    var body: some View {
        let isPausedOrStopped = clientState.areAllGroupsPaused || clientState.units.allSatisfy { unit in
            let unitState = unit.state.uppercased()
            return unitState == "PAUSE" || unitState == "PAUSED" || unitState == "STOP" || unitState == "STOPPED"
        }
        
        HStack(spacing: 8) {
            if isPausedOrStopped {
                Button(action: { client.fold() }) {
                    Label("Resume All", systemImage: "arrow.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            } else {
                Button(action: { client.pause() }) {
                    Label("Pause All", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
            
            Button(action: { client.finish() }) {
                Label("Finish All", systemImage: "stop.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }
}