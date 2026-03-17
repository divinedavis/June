import SwiftUI

struct FalconLogo: View {
    var size: CGFloat = 40
    var color: Color = .juneAccent

    var body: some View {
        Canvas { ctx, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let sx = w / 100
            let sy = h / 100

            // Head
            ctx.fill(
                Path(ellipseIn: CGRect(x: 52 * sx, y: 12 * sy, width: 20 * sx, height: 20 * sy)),
                with: .color(color)
            )

            // Beak
            var beak = Path()
            beak.move(to: CGPoint(x: 70 * sx, y: 19 * sy))
            beak.addLine(to: CGPoint(x: 84 * sx, y: 22 * sy))
            beak.addLine(to: CGPoint(x: 70 * sx, y: 26 * sy))
            beak.closeSubpath()
            ctx.fill(beak, with: .color(color))

            // Eye
            ctx.fill(
                Path(ellipseIn: CGRect(x: 62 * sx, y: 17 * sy, width: 6 * sx, height: 6 * sy)),
                with: .color(.black)
            )
            ctx.fill(
                Path(ellipseIn: CGRect(x: 63.5 * sx, y: 17 * sy, width: 2.5 * sx, height: 2.5 * sy)),
                with: .color(.white)
            )

            // Body
            var body = Path()
            body.move(to: CGPoint(x: 28 * sx, y: 45 * sy))
            body.addCurve(
                to: CGPoint(x: 70 * sx, y: 45 * sy),
                control1: CGPoint(x: 42 * sx, y: 28 * sy),
                control2: CGPoint(x: 60 * sx, y: 30 * sy)
            )
            body.addCurve(
                to: CGPoint(x: 52 * sx, y: 70 * sy),
                control1: CGPoint(x: 74 * sx, y: 56 * sy),
                control2: CGPoint(x: 66 * sx, y: 66 * sy)
            )
            body.addCurve(
                to: CGPoint(x: 28 * sx, y: 45 * sy),
                control1: CGPoint(x: 38 * sx, y: 74 * sy),
                control2: CGPoint(x: 24 * sx, y: 60 * sy)
            )
            ctx.fill(body, with: .color(color))

            // Left wing
            var wing = Path()
            wing.move(to: CGPoint(x: 28 * sx, y: 45 * sy))
            wing.addCurve(
                to: CGPoint(x: 6 * sx, y: 52 * sy),
                control1: CGPoint(x: 18 * sx, y: 34 * sy),
                control2: CGPoint(x: 6 * sx, y: 40 * sy)
            )
            wing.addCurve(
                to: CGPoint(x: 26 * sx, y: 62 * sy),
                control1: CGPoint(x: 12 * sx, y: 62 * sy),
                control2: CGPoint(x: 20 * sx, y: 60 * sy)
            )
            wing.addCurve(
                to: CGPoint(x: 28 * sx, y: 45 * sy),
                control1: CGPoint(x: 28 * sx, y: 68 * sy),
                control2: CGPoint(x: 34 * sx, y: 56 * sy)
            )
            ctx.fill(wing, with: .color(color))

            // Tail feathers
            let tailColor = color.opacity(0.9)
            var stroke1 = Path()
            stroke1.move(to: CGPoint(x: 38 * sx, y: 68 * sy))
            stroke1.addCurve(
                to: CGPoint(x: 30 * sx, y: 90 * sy),
                control1: CGPoint(x: 34 * sx, y: 76 * sy),
                control2: CGPoint(x: 28 * sx, y: 84 * sy)
            )
            ctx.stroke(stroke1, with: .color(tailColor), lineWidth: 5 * sx)

            var stroke2 = Path()
            stroke2.move(to: CGPoint(x: 48 * sx, y: 70 * sy))
            stroke2.addCurve(
                to: CGPoint(x: 44 * sx, y: 92 * sy),
                control1: CGPoint(x: 46 * sx, y: 80 * sy),
                control2: CGPoint(x: 42 * sx, y: 88 * sy)
            )
            ctx.stroke(stroke2, with: .color(tailColor), lineWidth: 5 * sx)

            var stroke3 = Path()
            stroke3.move(to: CGPoint(x: 56 * sx, y: 68 * sy))
            stroke3.addCurve(
                to: CGPoint(x: 58 * sx, y: 88 * sy),
                control1: CGPoint(x: 58 * sx, y: 76 * sy),
                control2: CGPoint(x: 60 * sx, y: 84 * sy)
            )
            ctx.stroke(stroke3, with: .color(tailColor), lineWidth: 4 * sx)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        Color.black
        FalconLogo(size: 120)
    }
}
