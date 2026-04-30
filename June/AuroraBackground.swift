import SwiftUI

/// Continuously animated warm-amber aurora over deep black, drifting slowly.
/// Used as the auth-screen backdrop. Pure SwiftUI — no asset, no video.
struct AuroraBackground: View {
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    Color.black

                    // Bottom-right warm gold wisp — primary glow
                    blob(
                        color: Color(red: 0.96, green: 0.78, blue: 0.42),
                        radius: max(geo.size.width, geo.size.height) * 0.85,
                        x: geo.size.width * 0.92 + cos(t * 0.13) * 70,
                        y: geo.size.height * 0.78 + sin(t * 0.11) * 90,
                        opacity: 0.55
                    )

                    // Bottom-left bronze accent
                    blob(
                        color: Color(red: 0.86, green: 0.50, blue: 0.20),
                        radius: max(geo.size.width, geo.size.height) * 0.7,
                        x: geo.size.width * 0.10 + cos(t * 0.09 + 2.1) * 80,
                        y: geo.size.height * 0.95 + sin(t * 0.13 + 1.0) * 60,
                        opacity: 0.40
                    )

                    // Top-right soft cream halo
                    blob(
                        color: Color(red: 0.98, green: 0.85, blue: 0.58),
                        radius: max(geo.size.width, geo.size.height) * 0.75,
                        x: geo.size.width * 0.78 + cos(t * 0.11 + 3.1) * 100,
                        y: geo.size.height * 0.10 + sin(t * 0.10 + 2.0) * 80,
                        opacity: 0.32
                    )

                    // Mid-left deep amber highlight
                    blob(
                        color: Color(red: 0.78, green: 0.42, blue: 0.18),
                        radius: max(geo.size.width, geo.size.height) * 0.6,
                        x: geo.size.width * 0.20 + cos(t * 0.10 + 4.2) * 70,
                        y: geo.size.height * 0.45 + sin(t * 0.12 + 3.3) * 110,
                        opacity: 0.32
                    )
                }
                .compositingGroup()
                .overlay(grain)
            }
        }
        .ignoresSafeArea()
    }

    private func blob(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(opacity), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius / 2
                )
            )
            .frame(width: radius, height: radius)
            .position(x: x, y: y)
            .blendMode(.plusLighter)
    }

    private var grain: some View {
        Canvas { ctx, size in
            // Sparse stardust grain — adds the dust/snow feel from the reference.
            var rng = SystemRandomNumberGenerator()
            let dotCount = Int(size.width * size.height / 1400)
            for _ in 0..<dotCount {
                let x = CGFloat(UInt64.random(in: 0...UInt64(size.width * 100), using: &rng)) / 100
                let y = CGFloat(UInt64.random(in: 0...UInt64(size.height * 100), using: &rng)) / 100
                let alpha = Double.random(in: 0.05...0.18, using: &rng)
                let radius: CGFloat = .random(in: 0.4...1.0, using: &rng)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                    with: .color(.white.opacity(alpha))
                )
            }
        }
        .allowsHitTesting(false)
        .blendMode(.plusLighter)
        .opacity(0.55)
    }
}

#Preview {
    AuroraBackground()
}
