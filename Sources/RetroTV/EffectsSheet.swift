import SwiftUI

/// Native panel for the TV's picture, sound and viewing options.
struct EffectsSheet: View {
    let controller: TVController
    @AppStorage("autoImmersive") private var autoImmersive = true
    @AppStorage("haptics") private var haptics = true
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(L10n.effectsNote)
                        .font(Theme.label(13, weight: .medium))
                        .foregroundStyle(Theme.dim)

                    section("Picture") {
                        tile("Noise level", "tv", detail: "Cycles 5 levels", key: .noise)
                        tile("Screen glow", "sun.max", detail: "On / off", key: .glow)
                        tile("Static between channels", "waveform", detail: "On / off", key: .staticTransition)
                        tile("Full screen", "arrow.up.left.and.arrow.down.right", detail: "Video fills the screen", key: .fullScreen)
                    }

                    if controller.decade.id == "70s" {
                        section("70s set") {
                            tile("Black & white", "circle.lefthalf.filled", detail: "On / off", key: .blackAndWhite)
                            tile("Green / orange room", "paintpalette", detail: "Switch", key: .colorScheme)
                        }
                    }

                    section("Playback") {
                        tile("Playlist mode", "list.number", detail: "Clips play start to end, then next channel", key: .playlist, on: controller.isPlaylist)
                        tile("Shuffle", "shuffle", detail: "Random years", key: .shuffle, on: controller.isShuffle)
                        tile("Sound effects", "speaker.wave.2", detail: "On / off", key: .mute)
                        tile("Focus on the TV", "rectangle.inset.filled", detail: "Hide the page around it", key: .immersive, on: controller.isImmersive)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        header("App")
                        VStack(spacing: 0) {
                            Toggle("Focus on the TV when a set opens", isOn: $autoImmersive)
                                .padding(14)
                            Divider().overlay(Theme.stroke)
                            Toggle("Button clicks (haptics)", isOn: $haptics)
                                .padding(14)
                        }
                        .font(Theme.label(15, weight: .medium))
                        .foregroundStyle(Theme.cream)
                        .tint(Theme.amber)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.panelHigh))
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                            Text(L10n.aboutTitle)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Theme.dim)
                        }
                        .font(Theme.label(15, weight: .semibold))
                        .foregroundStyle(Theme.cream)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.panelHigh))
                    }
                }
                .padding(18)
            }
            .background(Theme.panel.ignoresSafeArea())
            .navigationTitle(L10n.effectsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(Theme.label(16, weight: .bold))
                        .tint(Theme.amber)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.panel)
    }

    private func header(_ title: String) -> some View {
        Text(title.uppercased())
            .font(Theme.label(12, weight: .heavy))
            .tracking(1.2)
            .foregroundStyle(Theme.amber)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            header(title)
            LazyVGrid(columns: columns, spacing: 10) {
                content()
            }
        }
    }

    private func tile(_ title: String, _ symbol: String, detail: String, key: RemoteKey, on: Bool = false) -> some View {
        Button {
            controller.press(key)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                    Spacer()
                    if on {
                        Text("ON")
                            .font(Theme.label(10, weight: .heavy))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Theme.amber))
                    }
                }
                Text(title)
                    .font(Theme.label(14, weight: .bold))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(Theme.label(11, weight: .medium))
                    .foregroundStyle(Theme.dim)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.panelHigh)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(on ? Theme.amber.opacity(0.7) : Theme.stroke, lineWidth: on ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(PressableStyle(scale: 0.96))
    }
}
