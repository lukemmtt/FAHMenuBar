import SwiftUI

struct ColoredProgressView: View {
    let value: Double
    let total: Double
    let tintColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Rectangle()
                    .frame(width: min(geometry.size.width * CGFloat(value / total), geometry.size.width), height: geometry.size.height)
                    .foregroundColor(tintColor)
                    .animation(.linear, value: value)
            }
        }
        .frame(height: 4)
        .cornerRadius(2)
    }
}