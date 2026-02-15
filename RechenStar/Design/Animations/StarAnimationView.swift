import SwiftUI

struct StarAnimationView: View {
    let starCount: Int
    let from: CGRect
    let to: CGRect
    let onComplete: () -> Void

    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<starCount, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.appSunYellow)
                    .scaleEffect(animate ? 0.4 : 1.0)
                    .opacity(animate ? 0.3 : 1.0)
                    .position(
                        x: animate ? to.midX : from.midX,
                        y: animate ? to.midY : from.midY
                    )
                    .animation(
                        .spring(duration: 0.5, bounce: 0.3)
                            .delay(Double(index) * 0.1),
                        value: animate
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            animate = true
            let totalDuration = 0.5 + Double(starCount - 1) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                onComplete()
            }
        }
    }
}
