import SwiftUI

struct ColoredProgressView: View {
    let value: Double
    let total: Double
    let tintColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 6)
                
                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(tintColor)
                    .frame(width: geometry.size.width * CGFloat(value / total), height: 6)
            }
        }
        .frame(height: 6)
    }
}