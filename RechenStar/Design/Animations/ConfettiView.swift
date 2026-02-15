import SwiftUI

struct ConfettiView: View {
    @State private var animate = false

    private let particles: [ConfettiParticle] = {
        let colors: [Color] = [
            .appSunYellow, .appSkyBlue, .appGrassGreen,
            .appCoral, .appPurple, .appOrange
        ]
        let screenWidth = UIScreen.main.bounds.width
        return (0..<50).map { _ in
            ConfettiParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...14),
                xPos: CGFloat.random(in: 20...(screenWidth - 20)),
                rotation: Double.random(in: 0...360),
                isCircle: Bool.random(),
                delay: Double.random(in: 0...0.6),
                duration: Double.random(in: 2.0...3.5),
                startY: CGFloat.random(in: -60...(-10))
            )
        }
    }()

    private let screenHeight = UIScreen.main.bounds.height

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                RoundedRectangle(cornerRadius: particle.isCircle ? particle.size : 2)
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .rotationEffect(.degrees(animate ? particle.rotation + 360 : particle.rotation))
                    .position(
                        x: particle.xPos,
                        y: animate ? screenHeight + 50 : particle.startY
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeIn(duration: particle.duration)
                            .delay(particle.delay),
                        value: animate
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                animate = true
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let xPos: CGFloat
    let rotation: Double
    let isCircle: Bool
    let delay: Double
    let duration: Double
    let startY: CGFloat
}
