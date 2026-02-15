import SwiftUI

struct ConfettiView: View {
    @State private var startTime: Date?
    private let particles = (0..<60).map { _ in ConfettiParticle() }
    private let duration: Double = 3.0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard let startTime else { return }
                let elapsed = timeline.date.timeIntervalSince(startTime)
                guard elapsed < duration + 1.0 else { return }

                for particle in particles {
                    let t = max(0, elapsed - particle.delay) / particle.fallDuration
                    guard t >= 0 && t <= 1.0 else { continue }

                    let x = particle.xFraction * size.width
                        + sin(t * .pi * particle.wobbleFrequency) * particle.wobbleAmount
                    let y = -20 + t * (size.height + 70)
                    let opacity = max(0, 1.0 - t * 1.2)
                    let rotation = Angle.degrees(particle.startRotation + t * 360)
                    let rect = CGRect(
                        x: x - particle.size / 2,
                        y: y - particle.size / 2,
                        width: particle.size,
                        height: particle.isCircle ? particle.size : particle.size * 0.6
                    )
                    let path = particle.isCircle
                        ? Path(ellipseIn: rect)
                        : Path(roundedRect: rect, cornerRadius: 1)

                    context.opacity = opacity
                    context.fill(
                        path.applying(.init(rotationAngle: rotation.radians)
                            .concatenating(.init(translationX: x, y: y))
                            .concatenating(.init(translationX: -x, y: -y))),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear {
            startTime = Date()
        }
    }
}

private struct ConfettiParticle {
    private static let colors: [Color] = [
        .appSunYellow, .appSkyBlue, .appGrassGreen,
        .appCoral, .appPurple, .appOrange
    ]

    let color: Color
    let size: CGFloat
    let xFraction: CGFloat
    let startRotation: Double
    let isCircle: Bool
    let delay: Double
    let fallDuration: Double
    let wobbleAmount: CGFloat
    let wobbleFrequency: Double

    init() {
        color = Self.colors.randomElement()!
        size = CGFloat.random(in: 6...14)
        xFraction = CGFloat.random(in: 0.05...0.95)
        startRotation = Double.random(in: 0...360)
        isCircle = Bool.random()
        delay = Double.random(in: 0...0.6)
        fallDuration = Double.random(in: 2.0...3.0)
        wobbleAmount = CGFloat.random(in: 10...30)
        wobbleFrequency = Double.random(in: 2...4)
    }
}
