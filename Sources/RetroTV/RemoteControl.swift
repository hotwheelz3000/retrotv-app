import SwiftUI

/// The native remote under the TV: power, channel and volume rockers, an LED
/// readout and a decade dial.
struct RemoteControl: View {
    let controller: TVController
    var compact = false
    let onEffects: () -> Void
    let onGuide: () -> Void

    var body: some View {
        VStack(spacing: compact ? 12 : 16) {
            HStack(alignment: .center, spacing: 14) {
                RoundRemoteButton(symbol: "power", tint: Theme.red, label: "POWER") {
                    controller.press(.power)
                }
                Button {
                    Haptics.click()
                    onGuide()
                } label: {
                    LEDDisplay(text: controller.ledText)
                }
                .buttonStyle(PressableStyle(scale: 0.97))
                .accessibilityLabel("Open guide")
                RoundRemoteButton(symbol: "list.bullet.rectangle", tint: Theme.panelHigh, label: "Guide") {
                    Haptics.click()
                    onGuide()
                }
            }

            HStack(alignment: .center, spacing: 14) {
                Rocker(title: "VOL", upSymbol: "plus", downSymbol: "minus") {
                    controller.press(.volumeUp)
                } down: {
                    controller.press(.volumeDown)
                }
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        PillButton(
                            symbol: controller.isFullScreen
                                ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                            title: controller.isFullScreen ? "Exit full" : "Full",
                            highlighted: controller.isFullScreen
                        ) { controller.press(.fullScreen) }
                        PillButton(
                            symbol: "shuffle",
                            title: "Shuffle",
                            highlighted: controller.isShuffle
                        ) { controller.press(.shuffle) }
                    }
                    HStack(spacing: 10) {
                        PillButton(
                            symbol: controller.isImmersive ? "rectangle.inset.filled" : "rectangle.dashed",
                            title: controller.isImmersive ? "Focus" : "Page",
                            highlighted: controller.isImmersive
                        ) { controller.press(.immersive) }
                        PillButton(symbol: "slider.horizontal.3", title: "Effects") {
                            Haptics.click()
                            onEffects()
                        }
                    }
                }
                Rocker(title: "CH", upSymbol: "chevron.up", downSymbol: "chevron.down") {
                    controller.press(.channelUp)
                } down: {
                    controller.press(.channelDown)
                }
            }

            DecadeDial(selected: controller.decade) { controller.tune(to: $0) }
        }
        .padding(.horizontal, 18)
        .padding(.top, compact ? 14 : 18)
        .padding(.bottom, compact ? 14 : 8)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.panelHigh, Theme.panel],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 20, y: -4)
        )
    }
}

struct LEDDisplay: View {
    let text: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
            Text(text)
                .font(Theme.led(18))
                .foregroundStyle(Theme.amber)
                .shadow(color: Theme.amber.opacity(0.8), radius: 6)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .animation(.snappy, value: text)
                .padding(.horizontal, 10)
            Scanlines(spacing: 2, opacity: 0.35)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
    }
}

struct RoundRemoteButton: View {
    let symbol: String
    let tint: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.cream)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(1), tint.opacity(0.7)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 3)
                )
        }
        .buttonStyle(PressableStyle(scale: 0.9))
        .accessibilityLabel(label)
    }
}

struct Rocker: View {
    let title: String
    let upSymbol: String
    let downSymbol: String
    let up: () -> Void
    let down: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            rockerHalf(symbol: upSymbol, action: up)
                .accessibilityLabel("\(title) up")
            Text(title)
                .font(Theme.label(11, weight: .heavy))
                .foregroundStyle(Theme.dim)
                .padding(.vertical, 2)
            rockerHalf(symbol: downSymbol, action: down)
                .accessibilityLabel("\(title) down")
        }
        .frame(width: 58)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.45))
                .overlay(Capsule(style: .continuous).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    private func rockerHalf(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Theme.cream)
                .frame(width: 58, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.85))
    }
}

struct PillButton: View {
    let symbol: String
    let title: String
    var highlighted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(Theme.label(10, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(highlighted ? Color.black : Theme.cream)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(highlighted ? Theme.amber : Color.white.opacity(0.07))
            )
        }
        .buttonStyle(PressableStyle())
    }
}

/// A row of every set (the seven decades and MTV Rewind); the current one glows.
struct DecadeDial: View {
    let selected: Decade
    let onSelect: (Decade) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Decade.sets) { decade in
                let isOn = decade == selected
                Button {
                    onSelect(decade)
                } label: {
                    Text(decade.id)
                        .font(Theme.label(decade.isMTV ? 12 : 14, weight: .heavy))
                        .foregroundStyle(isOn ? Color.black : Theme.dim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isOn ? decade.glow : Color.clear)
                                .shadow(color: isOn ? decade.glow.opacity(0.7) : .clear, radius: 8)
                        )
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(decade.name)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Capsule(style: .continuous).fill(Color.black.opacity(0.4)))
        .animation(.snappy, value: selected)
    }
}
