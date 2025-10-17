import SwiftUI

struct WaveformView: View {
    var samples: [Float]
    var color: Color = .blue

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 1) {
                ForEach(samples.indices, id: \.self) { idx in
                    let sample = samples[idx]
                    // Chuyển giá trị mẫu về (0...1)
                    let normalized = CGFloat(max(0.05, min(1.0, abs(sample))))
                    let height = normalized * geo.size.height
                    Capsule()
                        .fill(color)
                        .frame(width: max(geo.size.width / CGFloat(max(samples.count, 1)), 2), height: height)
                }
            }
        }
        .frame(height: 40)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .animation(.linear(duration: 0.1), value: samples)
    }
}
