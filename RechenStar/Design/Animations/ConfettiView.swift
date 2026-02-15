import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animate = false

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
                        .rotationEffect(.degrees(animate ? particle.rotation + 360 : particle.rotation))
                        .position(
                            x: particle.x * geometry.size.width,
                            y: animate
                                ? geometry.size.height + 50
                                : -20 - particle.startOffset
                        )
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeIn(duration: particle.duration)
                                .delay(particle.delay),
                            value: animate
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            particles = (0..<50).map { _ in
                ConfettiParticle(
                    color: colors.randomElement()!,
                    size: CGFloat.random(in: 6...14),
                    x: CGFloat.random(in: 0.05...0.95),
                    rotation: Double.random(in: 0...360),
                    shape: Bool.random() ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 2)),
                    delay: Double.random(in: 0...0.5),
                    duration: Double.random(in: 2.0...3.5),
                    startOffset: CGFloat.random(in: 0...40)
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animate = true
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let rotation: Double
    let shape: AnyShape
    let delay: Double
    let duration: Double
    let startOffset: CGFloat
}
