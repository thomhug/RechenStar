import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    private let colors: [Color] = [
        .appSunYellow, .appSkyBlue, .appGrassGreen,
        .appCoral, .appPurple, .appOrange
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    particle.shape
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .rotationEffect(.degrees(isAnimating ? particle.rotation + 360 : particle.rotation))
                        .position(
                            x: particle.x * geometry.size.width,
                            y: isAnimating ? geometry.size.height + 50 : -50
                        )
                        .opacity(isAnimating ? 0 : 1)
                }
            }
            .onAppear {
                particles = (0..<40).map { _ in
                    ConfettiParticle(
                        color: colors.randomElement()!,
                        size: CGFloat.random(in: 6...14),
                        x: CGFloat.random(in: 0...1),
                        rotation: Double.random(in: 0...360),
                        shape: Bool.random() ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 2))
                    )
                }

                withAnimation(.easeIn(duration: 2.5)) {
                    isAnimating = true
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let rotation: Double
    let shape: AnyShape
}
