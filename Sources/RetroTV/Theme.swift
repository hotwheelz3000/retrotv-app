import SwiftUI
import UIKit

/// Colors and type for the whole app: a dark living room lit by a warm CRT glow.
enum Theme {
    static let background = Color(red: 0.055, green: 0.047, blue: 0.043)
    static let panel = Color(red: 0.118, green: 0.102, blue: 0.090)
    static let panelHigh = Color(red: 0.170, green: 0.148, blue: 0.130)
    static let stroke = Color.white.opacity(0.08)
    static let amber = Color(red: 1.0, green: 0.69, blue: 0.16)
    static let cream = Color(red: 0.96, green: 0.91, blue: 0.81)
    static let dim = Color(red: 0.96, green: 0.91, blue: 0.81).opacity(0.55)
    static let red = Color(red: 0.90, green: 0.26, blue: 0.21)

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
enum Haptics {
    static var enabled: Bool {
        UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true
    }

    static func click() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.8)
    }

    static func thunk() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func tick() {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

/// Buttons that sink a little when pressed, like a real remote.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
