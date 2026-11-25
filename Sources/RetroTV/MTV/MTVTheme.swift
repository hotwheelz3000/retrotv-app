import SwiftUI
import UIKit

extension Color {
    /// A color from a hex number, e.g. `Color(hex: 0x2F5EB0)`.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// The MTV Rewind sheets' colors, mapped onto the app's own living-room palette
/// (dark wood, cream, amber), so MTV Rewind looks like the other sets. Only its
/// VHS title keeps the lavender.
enum MTVTheme {
    static let background = Theme.panel
    static let royal = Color.white.opacity(0.4)
    static let deep = Theme.panelHigh
    static let navy = Theme.panelHigh
    static let lilac = Decade.mtv.glow
    static let yellow = Theme.amber
    static let red = Theme.red
    static let salmon = Theme.red
    static let lightBlue = Theme.cream
    static let pink = Theme.amber
    static let purple = Theme.amber
    static let sky = Theme.amber
    static let ink = Color(hex: 0x141420)

    static let enter = LinearGradient(
        colors: [Theme.amber, Color(red: 0.95, green: 0.45, blue: 0.12)], startPoint: .top, endPoint: .bottom
    )

    static let panel = Theme.panel
    static let panelHigh = Theme.panelHigh
    static let stroke = Theme.stroke
    static let cyan = Theme.amber
    static let text = Theme.cream
    static let dim = Theme.dim

    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func label(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func led(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}

/// Small physical clicks for remote buttons.
@MainActor
enum MTVHaptics {
    static func click() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.8)
    }

    static func thunk() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func tick() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

/// Buttons that sink a little when pressed, like a real remote.
struct MTVPressableStyle: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Thin dark lines across the picture, like a CRT.
struct MTVScanlines: View {
    var spacing: CGFloat = 3
    var opacity: Double = 0.22

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                context.fill(
                    Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                    with: .color(.black.opacity(opacity))
                )
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

/// Chunky cartoon lettering: a dark outline and a drop shadow, like the site's logo.
struct Outlined: ViewModifier {
    var width: CGFloat = 1.5
    var drop: CGFloat = 2.5

    func body(content: Content) -> some View {
        content
            .shadow(color: MTVTheme.ink, radius: 0, x: width, y: width)
            .shadow(color: MTVTheme.ink, radius: 0, x: -width, y: -width)
            .shadow(color: MTVTheme.ink, radius: 0, x: width, y: -width)
            .shadow(color: MTVTheme.ink, radius: 0, x: -width, y: width)
            .shadow(color: MTVTheme.ink.opacity(0.9), radius: 0, x: drop, y: drop)
    }
}

extension View {
    func outlined(_ width: CGFloat = 1.5, drop: CGFloat = 2.5) -> some View {
        modifier(Outlined(width: width, drop: drop))
    }
}

/// The VHS "REWIND" title colors: lavender letters with a dark brown 3D extrusion.
extension MTVTheme {
    static let titleFace = Color(hex: 0xA99CDA)
    static let titleExtrude = Color(hex: 0x3A2A22)

    /// Heavy, condensed, slightly slanted capitals, like the old VHS title.
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black).width(.condensed).italic()
    }
}

/// Lavender lettering with a stepped brown extrusion down and to the right, and a
/// thin dark outline. Lettering only, not a logo.
struct VHSTitle: ViewModifier {
    var depth: Int = 4

    func body(content: Content) -> some View {
        ZStack {
            ForEach((1...max(depth, 1)).reversed(), id: \.self) { step in
                content
                    .foregroundStyle(step == depth ? MTVTheme.ink : MTVTheme.titleExtrude)
                    .offset(x: CGFloat(step), y: CGFloat(step))
            }
            content
                .foregroundStyle(MTVTheme.titleFace)
                .shadow(color: MTVTheme.ink, radius: 0, x: 0.8, y: 0.8)
                .shadow(color: MTVTheme.ink, radius: 0, x: -0.8, y: -0.8)
                .shadow(color: MTVTheme.ink, radius: 0, x: 0.8, y: -0.8)
                .shadow(color: MTVTheme.ink, radius: 0, x: -0.8, y: 0.8)
        }
    }
}

extension View {
    func vhsTitle(depth: Int = 4) -> some View {
        modifier(VHSTitle(depth: depth))
    }
}

/// The app name in the VHS title style: "MTV" over "REWIND".
struct Wordmark: View {
    var size: CGFloat = 22
    var alignment: HorizontalAlignment = .center

    var body: some View {
        VStack(alignment: alignment, spacing: -size * 0.12) {
            Text("MTV")
                .font(MTVTheme.title(size * 0.8))
                .tracking(2)
                .vhsTitle(depth: max(2, Int(size / 10)))
            Text("REWIND")
                .font(MTVTheme.title(size * 1.15))
                .tracking(1.5)
                .vhsTitle(depth: max(3, Int(size / 6)))
        }
        .padding(.trailing, size / 5)
        .padding(.bottom, size / 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("MTV Rewind")
    }
}
