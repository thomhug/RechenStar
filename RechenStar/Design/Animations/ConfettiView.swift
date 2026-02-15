import SwiftUI

struct ConfettiView: View {
    @State private var startTime: Date?
    private let particles = (0..<60).map { _ in ConfettiParticle() }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard let startTime else { return }
                let elapsed = timeline.date.timeIntervalSince(startTime)
                guard elapsed < 4.0 else { return }

                for particle in particles {
                    let t = max(0, elapsed - particle.delay) / particle.fallDuration
                    guard t >= 0 && t <= 1.0 else { continue }

                    let x = particle.xFraction * size.width
                        + sin(t * .pi * particle.wobbleFrequency) * particle.wobbleAmount
                    let y = -20 + t * (size.height + 70)
                    let opacity = max(0, 1.0 - t * 1.3)

                    let w = particle.size
                    let h = particle.isCircle ? w : w * 0.6
                    let rect = CGRect(x: x - w / 2, y: y - h / 2, width: w, height: h)

                    context.opacity = opacity
                    if particle.isCircle {
                        context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                    } else {
                        context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(particle.color))
                    }
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
    let isCircle: Bool
    let delay: Double
    let fallDuration: Double
    let wobbleAmount: CGFloat
    let wobbleFrequency: Double

    init() {
        color = Self.colors.randomElement()!
        size = CGFloat.random(in: 8...16)
        xFraction = CGFloat.random(in: 0.05...0.95)
        isCircle = Bool.random()
        delay = Double.random(in: 0...0.6)
        fallDuration = Double.random(in: 2.0...3.0)
        wobbleAmount = CGFloat.random(in: 15...35)
        wobbleFrequency = Double.random(in: 2...4)
    }
}
