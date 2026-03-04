import SwiftUI

struct WaveformView: View {
    var isActive: Bool
    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let midY = height / 2
                let amplitude: Double = isActive ? 30 : 8
                var path = Path()
                path.move(to: CGPoint(x: 0, y: midY))
                for x in stride(from: 0, through: width, by: 2) {
                    let relX = x / width
                    let y = midY + amplitude * sin(relX * 4 * .pi + phase)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                context.stroke(path, with: .color(.orange), lineWidth: 3)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
        .onChange(of: isActive) { _, _ in phase = 0 }
    }
}
