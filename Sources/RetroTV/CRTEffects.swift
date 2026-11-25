import SwiftUI

/// Thin dark horizontal lines, like the rows of a CRT picture.
struct Scanlines: View {
    var spacing: CGFloat = 3
    var opacity: Double = 0.22

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black.opacity(opacity)))
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

/// Animated TV snow.
struct StaticNoise: View {
    var cell: CGFloat = 5
    var brightness: Double = 0.85

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 18.0)) { _ in
            Canvas { context, size in
                let columns = Int(size.width / cell) + 1
                let rows = Int(size.height / cell) + 1
                for row in 0..<rows {
                    for column in 0..<columns {
                        let level = Double.random(in: 0...brightness)
                        let rect = CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
                        context.fill(Path(rect), with: .color(Color(white: level)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// The classic CRT switch-on: a bright line opens into the picture, then fades away.
struct PowerOnFlash: View {
    @State private var widthScale: CGFloat = 0
    @State private var heightScale: CGFloat = 0.006
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            Color.black
            Rectangle()
                .fill(Color.white)
                .scaleEffect(x: widthScale, y: heightScale)
                .shadow(color: .white, radius: 12)
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .task {
            withAnimation(.easeOut(duration: 0.18)) { widthScale = 1 }
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.easeIn(duration: 0.22)) { heightScale = 1 }
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeOut(duration: 0.35)) { opacity = 0 }
        }
    }
}

/// A drawn TV set for the home screen, in the style of its decade.
struct TVSetView: View {
    let decade: Decade
    var showsLabel = true

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack(alignment: .top) {
                if hasAntenna {
                    antenna(width: width)
                }
                VStack(spacing: 0) {
                    cabinet(width: width, height: height * bodyFraction)
                    feet(width: width, height: height * (1 - bodyFraction - antennaFraction))
                }
                .padding(.top, height * antennaFraction)
            }
        }
        .aspectRatio(1.05, contentMode: .fit)
    }

    private var hasAntenna: Bool {
        [.console, .spaceAge, .woodgrain].contains(decade.style)
    }

    private var antennaFraction: CGFloat { hasAntenna ? 0.16 : 0.04 }
    private let bodyFraction: CGFloat = 0.72

    private var screenCorner: CGFloat {
        switch decade.style {
        case .flat: return 3
        case .silver: return 10
        case .boxy, .crt: return 16
        default: return 22
        }
    }

    private var bezel: CGFloat {
        switch decade.style {
        case .flat: return 4
        case .silver: return 10
        default: return 12
        }
    }

    private var hasSidePanel: Bool {
        [.console, .woodgrain, .boxy].contains(decade.style)
    }

    private func antenna(width: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Theme.cream.opacity(0.55)).frame(width: 2.5, height: width * 0.22)
                .rotationEffect(.degrees(-28), anchor: .bottom)
            Capsule().fill(Theme.cream.opacity(0.55)).frame(width: 2.5, height: width * 0.20)
                .rotationEffect(.degrees(24), anchor: .bottom)
            Ellipse().fill(Color.black.opacity(0.8)).frame(width: width * 0.12, height: width * 0.05)
                .offset(y: width * 0.10)
        }
        .frame(maxWidth: .infinity)
        .offset(y: -width * 0.02)
    }

    private func cabinet(width: CGFloat, height: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: decade.style == .flat ? 6 : 18, style: .continuous)
        return HStack(spacing: bezel * 0.8) {
            screen
            if hasSidePanel {
                sidePanel(width: width * 0.16)
            }
        }
        .padding(bezel)
        .frame(width: width, height: height)
        .background(
            shape.fill(LinearGradient(colors: decade.cabinet, startPoint: .top, endPoint: .bottom))
        )
        .overlay(woodGrain.clipShape(shape))
        .overlay(shape.strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: decade.glow.opacity(0.25), radius: 18, y: 4)
    }

    @ViewBuilder
    private var woodGrain: some View {
        if decade.style == .console || decade.style == .woodgrain {
            Canvas { context, size in
                var y: CGFloat = 4
                var seed = 7
                while y < size.height {
                    seed = (seed * 37 + 11) % 97
                    let wobble = CGFloat(seed % 5)
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addCurve(
                        to: CGPoint(x: size.width, y: y + wobble),
                        control1: CGPoint(x: size.width * 0.3, y: y - wobble),
                        control2: CGPoint(x: size.width * 0.7, y: y + wobble * 2)
                    )
                    context.stroke(path, with: .color(.black.opacity(0.12)), lineWidth: 1)
                    y += 6 + CGFloat(seed % 4)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private var screen: some View {
        let shape = RoundedRectangle(cornerRadius: screenCorner, style: .continuous)
        return ZStack {
            shape.fill(
                RadialGradient(
                    colors: [decade.glow.opacity(0.95), decade.glow.opacity(0.35), Color.black.opacity(0.95)],
                    center: .center, startRadius: 2, endRadius: 90
                )
            )
            if showsLabel {
                Text(decade.id)
                    .font(Theme.display(30))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .shadow(color: decade.glow, radius: 8)
                    .shadow(color: decade.glow.opacity(0.7), radius: 2)
                    .minimumScaleFactor(0.5)
            }
            // Glass highlight.
            shape.fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.22), Color.clear],
                    startPoint: .topLeading, endPoint: .center
                )
            )
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.black.opacity(0.6), lineWidth: 3))
    }

    private func sidePanel(width: CGFloat) -> some View {
        VStack(spacing: width * 0.25) {
            ForEach(0..<2, id: \.self) { _ in
                Circle()
                    .fill(
                        LinearGradient(colors: [Color(white: 0.75), Color(white: 0.30)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(Capsule().fill(Color.black.opacity(0.5)).frame(width: 2, height: width * 0.35))
                    .frame(width: width * 0.62, height: width * 0.62)
            }
            if decade.style == .boxy {
                VStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.25)).frame(height: 3)
                    }
                }
            } else {
                VStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle().fill(Color.black.opacity(0.35)).frame(height: 1.5)
                    }
                }
            }
        }
        .frame(width: width)
    }

    @ViewBuilder
    private func feet(width: CGFloat, height: CGFloat) -> some View {
        switch decade.style {
        case .console, .spaceAge:
            HStack {
                leg.rotationEffect(.degrees(8))
                Spacer()
                leg.rotationEffect(.degrees(-8))
            }
            .padding(.horizontal, width * 0.12)
            .frame(height: height)
        case .flat:
            VStack(spacing: 0) {
                Rectangle().fill(Color(white: 0.2)).frame(width: width * 0.05, height: height * 0.5)
                Capsule().fill(Color(white: 0.22)).frame(width: width * 0.4, height: height * 0.18)
            }
            .frame(height: height, alignment: .top)
        default:
            HStack {
                Capsule().fill(Color.black.opacity(0.7)).frame(width: width * 0.12, height: 5)
                Spacer()
                Capsule().fill(Color.black.opacity(0.7)).frame(width: width * 0.12, height: 5)
            }
            .padding(.horizontal, width * 0.1)
            .frame(height: height, alignment: .top)
        }
    }

    private var leg: some View {
        Capsule()
            .fill(LinearGradient(colors: decade.cabinet.reversed(), startPoint: .top, endPoint: .bottom))
            .frame(width: 5)
    }
}
