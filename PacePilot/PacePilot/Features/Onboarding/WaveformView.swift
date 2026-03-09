import SwiftUI

/// Voice Memos-style animated waveform bar visualizer.
/// Bars oscillate with varying heights and phases when `isActive` is true,
/// and collapse to minimal height when false.
struct WaveformView: View {
    var isActive: Bool

    private let barCount = 36

    // Deterministic per-bar animation parameters
    private func duration(_ i: Int) -> Double {
        [0.35, 0.50, 0.28, 0.45, 0.60, 0.32, 0.42, 0.55][i % 8]
    }

    private func delay(_ i: Int) -> Double {
        [0.00, 0.12, 0.07, 0.20, 0.05, 0.17, 0.25, 0.10][i % 8]
    }

    private func activeHeight(_ i: Int) -> CGFloat {
        // Bell-curve envelope: center bars taller, edges shorter
        let center = Double(barCount - 1) / 2.0
        let normalized = 1.0 - abs(Double(i) - center) / center
        let envelope = pow(max(normalized, 0), 0.5)
        let variation = [1.0, 0.55, 0.85, 0.45, 0.75, 0.50, 0.95, 0.65][i % 8]
        return CGFloat(envelope * variation * 38.0 + 5.0)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { i in
                _Bar(
                    isActive: isActive,
                    duration: duration(i),
                    delay: delay(i),
                    activeHeight: activeHeight(i)
                )
            }
        }
    }
}

private struct _Bar: View {
    let isActive: Bool
    let duration: Double
    let delay: Double
    let activeHeight: CGFloat

    @State private var height: CGFloat = 3

    var body: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 3, height: height)
            .onAppear { animate() }
            .onChange(of: isActive) { _, _ in animate() }
    }

    private func animate() {
        if isActive {
            withAnimation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) {
                height = activeHeight
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                height = 3
            }
        }
    }
}

#if DEBUG
#Preview("Waveform Active") {
    WaveformView(isActive: true)
        .frame(height: 60)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}

#Preview("Waveform Idle") {
    WaveformView(isActive: false)
        .frame(height: 60)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
#endif
